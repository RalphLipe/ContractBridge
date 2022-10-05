//
//  StatisticalAnalysis.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import Foundation


public struct LeadStatistics: Comparable {
    public var averageTricks: Double
    public var percentMaking: Double
    
    public init() {
        averageTricks = 0.0
        percentMaking = 0.0
    }
    
    public init(averageTricks: Double, percentMaking: Double) {
        self.averageTricks = averageTricks
        self.percentMaking = percentMaking
    }
    
    
    // A "better" lead has the highest percentage making AND the most total tricks
    public static func < (lhs: LeadStatistics, rhs: LeadStatistics) -> Bool {
        return lhs.percentMaking < rhs.percentMaking || (lhs.percentMaking == rhs.percentMaking && lhs.averageTricks < rhs.averageTricks)
    }
}




public struct StatsCacheKey: Hashable, Equatable {
    public let holding: VariableHolding
    public let requiredTricks: Int
    public let leadOption: LeadOption
}

public class StatsCache {
    // TODO: Dumb naming -- Think of something better than cache.cache[key[
    public var cache = [StatsCacheKey: StatisticalAnalysis]()
    public init() {}
}


public class StatisticalAnalysis {
    public let holding: VariableHolding
    public let leadPair: Pair
    public let leadOption: LeadOption
    public let requiredTricks: Int
    public let bestStats: LeadStatistics
    private var leadAnalyses: [LeadAnalysis]
    private let leadPlans: [LeadPlan]
    private let layouts: [VariableCombination]
    private var bestLeadIndex: Array<LeadPlan>.Index

    
    public static func analyze(holding: VariableHolding, leadPair: Pair, requiredTricks: Int, leadOption: LeadOption = .considerAll, cache: StatsCache?) -> StatisticalAnalysis {
        let key = StatsCacheKey(holding: holding, requiredTricks: requiredTricks, leadOption: leadOption)
        if let cache = cache {
         //   print("CACHE HIT")
            if let sa = cache.cache[key] { return sa }
        }
        let cache = cache ?? StatsCache()
        let sa = StatisticalAnalysis(holding: holding, leadPair: leadPair, requiredTricks: requiredTricks, leadOption: leadOption, cache: cache)
        cache.cache[key] = sa
        return sa
    }
    
    internal init(holding: VariableHolding, leadPair: Pair, requiredTricks: Int, leadOption: LeadOption, cache: StatsCache) {
        self.holding = holding
        self.layouts = holding.combinationHoldings()
        self.leadPair = leadPair
        self.requiredTricks = requiredTricks
        self.leadOption = leadOption
       // assert(holding.holdsRanks(leadPair))
        self.leadPlans = LeadGenerator.generateLeads(holding: holding, pair: leadPair, option: leadOption)
        assert(leadPlans.count > 0)
        self.leadAnalyses = []
        leadAnalyses.reserveCapacity(leadPlans.count * layouts.count)
        self.bestLeadIndex = 0
        var best = LeadStatistics()
        for i in leadPlans.indices {
            var stats = LeadStatistics()
            for layout in layouts {
                let result = LeadAnalyzer.statistical(holding: layout, leadPlan: leadPlans[i], requiredTricks: requiredTricks, leadOption: leadOption, cache: cache)
                leadAnalyses.append(result)
                let count = Double(layout.combinations)
                let c = Double(count)
                stats.averageTricks += result.stats.averageTricks * c
                stats.percentMaking += result.stats.percentMaking * c
            }
            // At this point stats needs to be divided by the total number of combinations
            // since each individual result was accumulated, weighted by the number of combinations
            // for a specific variable combination holding.
            let c = Double(holding.combinations)
            stats.averageTricks /= c
            stats.percentMaking /= c
            if stats > best {
                best = stats
                bestLeadIndex = i
            }
        }
        self.bestStats = best
    }
        
    
    private func analysisFor(lead: Array<LeadPlan>.Index, layout: Array<VariableCombination>.Index) -> LeadAnalysis {
        return leadAnalyses[(lead * layouts.count) + layout]
    }
    
    private func statsFor(lead: Array<LeadPlan>.Index) -> LeadStatistics {
        var stats = LeadStatistics()
        for j in layouts.indices {
            let c = Double(layouts[j].combinations)
            let a = analysisFor(lead: lead, layout: j)
            stats.averageTricks += a.stats.averageTricks * c
            stats.percentMaking += a.stats.percentMaking * c
        }
        let c = Double(holding.combinations)
        stats.averageTricks /= c
        stats.percentMaking /= c
        return stats
    }
    
    public var leadStatistics: [LeadPlan: LeadStatistics] {
        var results = [LeadPlan: LeadStatistics]()
        for i in leadPlans.indices {
            results[leadPlans[i]] = statsFor(lead: i)
        }
        return results
    }
    
    public var bestLeads: Set<LeadPlan> {
        var results = Set<LeadPlan>()
        for i in leadPlans.indices {
            if statsFor(lead: i) == bestStats {
                results.insert(leadPlans[i])
            }
        }
        return results
    }

    // This method is used interanally to find the statistics for the best lead
    // taken for a specific variable combination.
    public func bestLeadStats(for vc: VariableCombination) -> LeadStatistics? {
        if let j = layouts.firstIndex(of: vc) {
            return analysisFor(lead: bestLeadIndex, layout: j).stats
        }
        return nil
    }
    
    /*
    public func layoutsMaking(atLeast requiredTricks: Int, for leadPlan: LeadPlan) -> [VariableCombination] {
        var making = [VariableCombination]()
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
    
    public func layoutsMaking(exactly requiredTricks: Int, for leadPlan: LeadPlan) -> [VariableCombination] {
        var making = [VariableCombination]()
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
     */
    
    public func leadAnalyses(for layout: VariableCombination) -> [LeadPlan: LeadAnalysis] {
        var results: [LeadPlan: LeadAnalysis] = [:]
        if let j = layouts.firstIndex(where: { $0 == layout }) {
            for i in leadPlans.indices {
                results[leadPlans[i]] = analysisFor(lead: i, layout: j)
            }
        }
        return results
    }
    
}
