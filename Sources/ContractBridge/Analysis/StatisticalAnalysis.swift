//
//  StatisticalAnalysis.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import Foundation


//public struct LayoutResult {
//    let holding: RankPositions
//    let representsCombinations: Int
//    let leadAnalyses: [LeadAnalysis]
//}

// Statitistical lead report.  This is the interesting result computed at the end...
public struct LeadStatistics: Comparable {
    public let totalTricks: Int     // The total number of tricks * combinations weather making or not
    public let combinationsMaking: Int  // Number of combinations making at leeast required tricks
    
    public init() {
        totalTricks = 0
        combinationsMaking = 0
    }
    
    public init(totalTricks: Int, combinationsMaking: Int) {
        self.totalTricks = totalTricks
        self.combinationsMaking = combinationsMaking
    }
    
    
    public func addResult(_ leadAnalysis: LeadAnalysis, combinations: Int, requiredTricks: Int) -> LeadStatistics {
        let tricksTaken = leadAnalysis.tricksTaken
        return LeadStatistics(totalTricks: self.totalTricks + (tricksTaken * combinations),
                              combinationsMaking: tricksTaken >= requiredTricks ? self.combinationsMaking + combinations : self.combinationsMaking)
    }

    
    // A "better" lead has the highest percentage making AND the most total tricks
    public static func < (lhs: LeadStatistics, rhs: LeadStatistics) -> Bool {
        return lhs.combinationsMaking < rhs.combinationsMaking || (lhs.combinationsMaking == rhs.combinationsMaking && lhs.totalTricks < rhs.totalTricks)
    }
}


// Partial layout has:
//  N/S holding
//  marked opponent positions
//  required tricks
//  lead options
//  stats are [SpecificLayoutSA]
//  [LeadStatistics]
//
//  SpecificLayoutSA has:
//      Normalized specific holding
//      # combinations represented
//      marked opponents
//      Required Tricks
//      LeadOptions
//      [LeadAnalysis]
//

// GRID VERSION:
//
//  Entire clsss:
//      leadPair
//      markedPositions
//      originalHolding
//      requiredTricks
//      Combinations considered
//      ** COMPUTED ONCE: combinationsMaking, totalTricks
//
// x-axis:
//      Lead Plan
// y-axis:
//      Suit Layout
//      Represents combinations
//
// Elements:
//      tricksTaken: Int        // Includes *this* play
//      play: [RankRange]
//
//  Things you can ask SA for:
//      leadStatistics(onlyBest: bool = false) -> [LeadStatistics]
//      layoutStatistics() -> [LayoutStatistics]    <<--- THIS MAY NOT BE NECESSARY!
//      play(leadPlan:, layout: , (optional - specific ranks) [Position: Rank]) -> StatisticalAnalysis
//
//  LeadStatistics contains:
//      leadPlan
//      combinationsMaking  ** Computed
//      totalTricks         ** Computed
//      ** layoutsMaking: [LAYOUTRESULTS] subset of below [layoutResults]
//      layoutResults: [LAYOUTRESULT]
//          layout: RankPositions
//          representsCombinations: Int
//          result:
//              tricksTaken: Int
//              play: [Position: RankRange] implemented as array
//
//  LayoutStatistics:
//      layout: RankPositions
//      representsCombinations: Int
//      leadResults: [ LEADRESULT ]
//          leadPlan
//          result:
//              tricksTaken
//              play
//

public struct StatisticalAnalysis {
    public let holding: RankPositions
    public let marked: RankSet
    public let leadPair: Pair
    public let leadOption: LeadOption
    public let requiredTricks: Int
    public let totalCombinations: Int
    public let bestStats: LeadStatistics
    public let numTricksBestLead: Int

    public var percentCombinationsMaking: Double {
        return percentCombinationsMaking(bestStats)
    }
    
    public func percentCombinationsMaking(_ leadStatistics: LeadStatistics) -> Double {
        return Double(leadStatistics.combinationsMaking) / Double(totalCombinations) * 100.0
    }
    
    // TODO: This is actuall the average for "making" tricks, not the actual average.
    // That would require
    public var averageTricks: Double {
        return averageTricks(bestStats)
    }
    
    public func averageTricks(_ leadStatistics: LeadStatistics) -> Double {
        return Double(leadStatistics.totalTricks) / Double(totalCombinations)
    }
    

    
    // TODO: The "holding" member will not be the same value passed in here.  Perhaps 2 parameters?  Not super
    // important but it should show the initial state of "holding" IMO
    public init(partialHolding: RankPositions, requiredTricks: Int, leadOption: LeadOption = .considerAll) {
        let leadPair: Pair = partialHolding.hasRanks(.ns) ? .ns : .ew
        if partialHolding.hasRanks(leadPair.opponents) {
            fatalError("Partial holding must only contain ranks for one pair")
        }
        var fullHolding = partialHolding
        fullHolding.reassignRanks(from: nil, to: leadPair.opponents.positions.0)
        self.init(holding: fullHolding, leadPair: leadPair, requiredTricks: requiredTricks, marked: RankSet(), leadOption: leadOption)
    }
    
    public init(holding: RankPositions, leadPair: Pair, requiredTricks: Int, marked: RankSet, leadOption: LeadOption) {
        let leadPlans = LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption)
        let layouts = holding.allPossibleLayouts(pair: leadPair.opponents, marked: marked)
        var ignored: [LeadAnalysis]? = nil
        self.init(holding: holding, leadPair: leadPair, requiredTricks: requiredTricks, marked: marked, leadOption: leadOption, leadPlans: leadPlans, layouts: layouts, leadAnalyses: &ignored)
    }
    
    internal init(holding: RankPositions, leadPair: Pair, requiredTricks: Int, marked: RankSet, leadOption: LeadOption, leadPlans: [LeadPlan], layouts: [LayoutCombinations], leadAnalyses: inout [LeadAnalysis]?) {
        self.holding = holding
        self.marked = marked
        self.leadPair = leadPair
        self.requiredTricks = requiredTricks
        self.leadOption = leadOption
        assert(holding.hasRanks(leadPair))
        if leadAnalyses != nil { leadAnalyses?.reserveCapacity(leadPlans.count * layouts.count) }
        var best = LeadStatistics()
        var bestTricks = 0
        let normHolding = holding.normalized()
        for lead in leadPlans {
            var stats = LeadStatistics()
            var layoutTricks = -1
            for layout in layouts {
               // assert(layout.holding == layout.holding.normalized())
                let result = LeadAnalyzer.statistical(holding: layout.holding, leadPlan: lead, marked: marked, requiredTricks: requiredTricks, leadOption: leadOption)
                // TODO: This is too slow and stupid...  But ok for now...
                if layout.holding.normalized() == normHolding {
                    layoutTricks = result.tricksTaken
                }
                if leadAnalyses != nil { leadAnalyses!.append(result) }
                stats = stats.addResult(result, combinations: layout.combinationsRepresented, requiredTricks: requiredTricks)
            }
            assert(layoutTricks >= 0)
            if stats > best {
                best = stats
                bestTricks = layoutTricks
            }
        }
        self.bestStats = best
        self.numTricksBestLead = bestTricks
        self.totalCombinations = layouts.reduce(0) { $0 + $1.combinationsRepresented }
    }
        
    /*
        
        let leadPlans = LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption)
        self.layoutResults = []
        let layouts = holding.allPossibleLayouts(pair: leadPair.opponents, marked: marked)
 //       layouts.forEach { print("\($0.holding)") }
        for layout in layouts {
            var leadAnalyses: [LeadAnalysis] = []
            leadAnalyses.reserveCapacity(leadPlans.count)
            for leadPlan in leadPlans {
                leadAnalyses.append(LeadAnalyzer.statistical(holding: layout.holding, leadPlan: leadPlan, marked: marked, requiredTricks: requiredTricks, leadOption: leadOption))
            }
            self.layoutResults.append(LayoutResult(holding: layout.holding.normalized(), representsCombinations: layout.combinationsRepresented, leadAnalyses: leadAnalyses))
        }
        leadsStatistics.reserveCapacity(leadPlans.count)
        for i in leadPlans.indices {
            var totalComb = 0
            var combMaking = 0
            var totalTricks = 0
            for layoutResult in layoutResults {
                totalComb += layoutResult.representsCombinations
                let numTricks = layoutResult.leadAnalyses[i].tricksTaken
                if layoutResult.leadAnalyses[i].tricksTaken >= requiredTricks {
                    combMaking += layoutResult.representsCombinations
                }
                totalTricks += (numTricks * layoutResult.representsCombinations)
            }
            leadsStatistics.append(LeadStatistics(totalCombinations: totalComb, leadPlan: leadPlans[i], combinationsMaking: combMaking, totalTricks:  totalTricks))
        }
        let best = leadsStatistics.max()!
        self.tricksTaken = best.totalTricks
        self.combinationsMaking = best.combinationsMaking
    
    }
    */
    /*
    public func leadAnalysis(for leadPlan: LeadPlan, holding: RankPositions) -> LeadAnalysis {
        let normPos = holding.normalized()
        for layoutResult in layoutResults {
            if layoutResult.holding == normPos {
                for leadAnalysis in layoutResult.leadAnalyses {
                    if leadAnalysis.leadPlan == leadPlan {
                        return leadAnalysis
                    }
                }
            }
        }
        fatalError()
    }
*/
    /*
    public struct LayoutTricks {
        public let holding: RankPositions
        public let representsCombinations: Int
        public let tricksTaken: Int
    }
    
    public func tricksForAllLayouts(for leadPlan: LeadPlan) -> [LayoutTricks] {
        var result = [LayoutTricks] ()
        result.reserveCapacity(layoutResults)
        guard let i = leadPlans.firstIndex(where: { $0 == leadPlan}) else { fatalError() }
        for layoutResult in layoutResults {
            result.append(LayoutTricks(holding: layoutResult.holding, representsCombinations: layoutResult.representsCombinations, tricksTaken: layoutResult.leadAnalyses[i].tricksTaken))
        }
        return result
    }
     */
    

}


public struct StatisticalWithLeads {
    public let analysis: StatisticalAnalysis
    let leadPlans: [LeadPlan]
    let layouts: [LayoutCombinations]
    let leadAnalyses: [LeadAnalysis]
   
    // DONT LIKE THIS DUPLICATED CODE
    // TODO: share code somehow...
    public init(partialHolding: RankPositions, requiredTricks: Int, leadOption: LeadOption = .considerAll) {
        let leadPair: Pair = partialHolding.hasRanks(.ns) ? .ns : .ew
        if partialHolding.hasRanks(leadPair.opponents) {
            fatalError("Partial holding must only contain ranks for one pair")
        }
        var fullHolding = partialHolding
        fullHolding.reassignRanks(from: nil, to: leadPair.opponents.positions.0)
        self.init(holding: fullHolding, leadPair: leadPair, requiredTricks: requiredTricks, marked: RankSet(), leadOption: leadOption)
    }
    
    public init(holding: RankPositions, leadPair: Pair, requiredTricks: Int, marked: RankSet, leadOption: LeadOption) {
        self.leadPlans = LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption)
        self.layouts = holding.allPossibleLayouts(pair: leadPair.opponents, marked: marked)
        var leadAnalyses: [LeadAnalysis]? = []
        self.analysis = StatisticalAnalysis(holding: holding, leadPair: leadPair, requiredTricks: requiredTricks, marked: marked, leadOption: leadOption, leadPlans: leadPlans, layouts: layouts, leadAnalyses: &leadAnalyses)
        self.leadAnalyses = leadAnalyses!
    }
    
    private func analysisFor(lead: Array<LeadPlan>.Index, layout: Array<LayoutCombinations>.Index) -> LeadAnalysis {
        return leadAnalyses[(lead * layouts.count) + layout]
    }
    
    public var leadStatistics: [LeadPlan: LeadStatistics] {
        var results = [LeadPlan: LeadStatistics]()
        for i in leadPlans.indices {
            var stats = LeadStatistics()
            for j in layouts.indices {
                stats = stats.addResult(analysisFor(lead: i, layout: j), combinations: layouts[j].combinationsRepresented, requiredTricks: analysis.requiredTricks)
            }
            results[leadPlans[i]] = stats
        }
        return results
    }
    
    public var bestLeads: Set<LeadPlan> {
        var results = Set<LeadPlan>()
        for i in leadPlans.indices {
            var stats = LeadStatistics()
            for j in layouts.indices {
                stats = stats.addResult(analysisFor(lead: i, layout: j), combinations: layouts[j].combinationsRepresented, requiredTricks: analysis.requiredTricks)
            }
            if stats == analysis.bestStats {
                results.insert(leadPlans[i])
            }
        }
        return results
    }

    public func layoutsMaking(atLeast requiredTricks: Int, for leadPlan: LeadPlan) -> [LayoutCombinations] {
        var making = [LayoutCombinations]()
        // TODO: Error checking ... what to do if leadplan cant be found
        let i = leadPlans.firstIndex(of: leadPlan)!
        for j in layouts.indices {
            let leadAnalysis = analysisFor(lead: i, layout: j)
            if leadAnalysis.tricksTaken >= requiredTricks {
                making.append(layouts[j])
            }
        }
        return making
    }
    
    public func layoutsMaking(exactly requiredTricks: Int, for leadPlan: LeadPlan) -> [LayoutCombinations] {
        var making = [LayoutCombinations]()
        // TODO: Error checking ... what to do if leadplan cant be found
        let i = leadPlans.firstIndex(of: leadPlan)!
        for j in layouts.indices {
            let leadAnalysis = analysisFor(lead: i, layout: j)
            if leadAnalysis.tricksTaken == requiredTricks {
                making.append(layouts[j])
            }
        }
        return making
    }
    
    public func leadAnalyses(for layout: RankPositions) -> [LeadPlan: LeadAnalysis] {
        var results: [LeadPlan: LeadAnalysis] = [:]
        if let j = layouts.firstIndex(where: { $0.holding == layout }) {
            for i in leadPlans.indices {
                results[leadPlans[i]] = analysisFor(lead: i, layout: j)
            }
        }
        return results
    }
    
}
