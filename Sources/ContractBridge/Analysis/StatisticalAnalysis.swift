//
//  StatisticalAnalysis.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import Foundation


public struct LayoutResult {
    let holding: RankPositions
    let representsCombinations: Int
    let leadAnalyses: [LeadAnalysis]
}

// Statitistical lead report.  This is the interesting result computed at the end...
public struct LeadStatistics {
    public let totalCombinations: Int
    public let leadPlan: LeadPlan
    public let combinationsMaking: Int
    public let totalTricks: Int
    
    public var averageTricks: Double { return Double(totalTricks) / Double(totalCombinations) }
    public var percentMaking: Double { return Double(combinationsMaking) / Double(totalCombinations) * 100.0 }
}


public struct StatisticalAnalysis {
    public let holding: RankPositions
    public let marked: RankSet
    public let leadPair: Pair
    public let leadOption: LeadOption
    public let requiredTricks: Int
    public private(set) var combinationsConsidered = 0
    public private(set) var leadsStatistics = [LeadStatistics]()
    private let leadPlans: [LeadPlan]
    private var layoutResults: [LayoutResult]
    
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
        self.holding = holding
        self.marked = marked
        self.leadPair = leadPair
        self.requiredTricks = requiredTricks
        self.leadOption = leadOption
        assert(holding.hasRanks(leadPair))
        self.leadPlans = LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption)
     ///   self.sl = []
        self.layoutResults = []
        let layouts = holding.allPossibleLayouts(pair: leadPair.opponents, marked: marked)
 //       layouts.forEach { print("\($0.holding)") }
        for layout in layouts {
            var leadAnalyses: [LeadAnalysis] = []
            for leadPlan in leadPlans {
  //              print("\(layout.holding)")
                leadAnalyses.append(LeadAnalysis(holding: layout.holding, leadPlan: leadPlan, marked: marked, requiredTricks: requiredTricks, leadOption: leadOption))
            }
            self.layoutResults.append(LayoutResult(holding: layout.holding.normalized(), representsCombinations: layout.combinationsRepresented, leadAnalyses: leadAnalyses))
        }
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
        leadsStatistics.sort(by: { $0.combinationsMaking < $1.combinationsMaking || ($0.combinationsMaking == $1.combinationsMaking && $0.totalTricks < $1.totalTricks)})
    }
    
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

    public struct LayoutTricks {
        public let holding: RankPositions
        public let representsCombinations: Int
        public let tricksTaken: Int
    }
    
    public func tricksForAllLayouts(for leadPlan: LeadPlan) -> [LayoutTricks] {
        var result = [LayoutTricks] ()
        var i = leadPlans.startIndex
        while i < self.leadPlans.endIndex && leadPlans[i] != leadPlan {
            i += 1
        }
        if i >= leadPlans.endIndex { fatalError() }
        for layoutResult in layoutResults {
            result.append(LayoutTricks(holding: layoutResult.holding, representsCombinations: layoutResult.representsCombinations, tricksTaken: layoutResult.leadAnalyses[i].tricksTaken))
        }
        return result
    }
 
}
