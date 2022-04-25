//
//  LeadAnalysis.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public struct TrickSequence {
    public let winningPosition: Position
    public let play: [Position: ClosedRange<Rank>]
}

public struct LayoutCombinations {
    public let layoutId: SuitLayoutIdentifier?
    public let combinations: Int
}

public struct LeadStatistics {
    public let leadPlan: LeadPlan
    public let maxTrickCombinations: [Int]
    public let layouts: [[LayoutCombinations]]
    public let maxTricksThisLayout: Int
    public let trickSequence: TrickSequence
    
    public var maxTricksAnyLayout: Int { return maxTrickCombinations.count - 1 }

    public func combinationsFor(desiredTricks: Int) -> Int {
        return maxTrickCombinations.count > desiredTricks ? maxTrickCombinations[desiredTricks] : 0
    }
    public func layoutsFor(_ desiredTricks: Int, mostCommonFirst: Bool = true) -> [LayoutCombinations] {
        var layouts = desiredTricks > layouts.count ? [] : layouts[desiredTricks]
        if mostCommonFirst {
            layouts.sort(by: { $0.combinations > $1.combinations })
        }
        return layouts
    }
    
    public func percentageFor(desiredTricks: Int) -> Double {
        return Double(maxTrickCombinations[desiredTricks]) / Double(maxTrickCombinations[0]) * 100.0
    }
}


public struct LayoutAnalysis {
    public let suitLayoutId: SuitLayoutIdentifier
    public let totalCombinations: Int
    public let worstCaseTricks: Int
    public let maxTricksThisLayout: Int
    public let maxTricksAllLayouts: Int
    public let leads: [LeadStatistics]
    
    
    public func bestLeads() -> [LeadStatistics] {
        return bestLeads(desiredTricks: maxTricksAllLayouts)
    }
    
    public func bestLeads(desiredTricks: Int) -> [LeadStatistics] {
        let bestCombinationCount = leads.reduce(0) { max($0, $1.combinationsFor(desiredTricks: desiredTricks))}
        return leads.filter { $0.combinationsFor(desiredTricks: desiredTricks) == bestCombinationCount}
    }
}


public class LayoutAnalyzer {
    public let suitHolding: SuitHolding
    public let worstCaseTricks: Int
    public internal(set) var combinations: Int
    
    internal let leads: [LeadPlan]
    private var trickSequences: [TrickSequence]
    private var layouts: [LayoutCombinations]
    // This array contains the max number of tricks with the x-axis is the lead, and the y is the deal
    // info.  maxTricks = maxTricks[leadIndex][layoutIndex]
    private var maxTricks: [[Int]]
    private var thisLayoutMaxTricks: [Int]

   
    internal init(suitHolding: SuitHolding, leads: [LeadPlan]) {
        self.suitHolding = suitHolding
        self.leads = leads
        self.worstCaseTricks = LayoutAnalyzer.computeMinTricks(suitHolding: suitHolding)
        self.layouts = []
        self.thisLayoutMaxTricks = []
        self.trickSequences = []
        self.maxTricks = Array<[Int]>(repeating: [], count: leads.count)

        self.combinations = 0
    }
    
    private class func computeMinTricks(suitHolding: SuitHolding) -> Int {
        let nRanks = suitHolding.initialLayout.ranksFor(position: .north)
        let sRanks = suitHolding.initialLayout.ranksFor(position: .south)
        let ewRanks = suitHolding.initialLayout.ranksFor(position: .east).union(suitHolding.initialLayout.ranksFor(position: .west))
        
        var nsSorted = Array(nRanks.union(sRanks))
        nsSorted.sort()
        nsSorted.reverse()
        var ewSorted = Array(ewRanks)
        ewSorted.sort()
        ewSorted.reverse()

        // N/S can only win as any tricks as the length of the longest hand  Strip off low cards
        let maxPossible = max(nRanks.count, sRanks.count)
        while nsSorted.count > maxPossible {
            _ = nsSorted.removeLast()
        }
        
        var minTricks = 0
        while ewSorted.count > 0 && nsSorted.count > 0 {
            let nsPlayed = nsSorted.removeFirst()
            if nsPlayed > ewSorted.first! {
                minTricks += 1
                _ = ewSorted.removeLast()
            } else {
                _ = ewSorted.removeFirst()
            }
        }
        return minTricks + nsSorted.count
    }
    
    
    internal func recordResults(_ results: [Int], layoutId: SuitLayoutIdentifier?, combinations: Int) -> Void {
        assert(results.count == self.leads.count)
        assert(self.maxTricks.count == results.count)
        assert(self.maxTricks[0].count == self.layouts.count)
        
        self.combinations += combinations
        layouts.append(LayoutCombinations(layoutId: layoutId, combinations: combinations))
        for i in results.indices {
            self.maxTricks[i].append(results[i])
        }
    }
    
    internal func recordTrickSequence(_ trickSequence: TrickSequence, maxTricks: Int) {
        thisLayoutMaxTricks.append(maxTricks)
        trickSequences.append(trickSequence)
    }
    
    private func statsFor(leadIndex: Int) -> LeadStatistics {
        let maxTricks = self.maxTricks[leadIndex].reduce(0) { max($0, $1) }
        var trickCombinations = Array<Int>(repeating: 0, count: maxTricks + 1)
        var leadLayouts = Array<[LayoutCombinations]>(repeating: [], count: maxTricks + 1)
        assert(self.layouts.count == self.maxTricks[leadIndex].count)
        for l in layouts.indices {
            var m = self.maxTricks[leadIndex][l]
            leadLayouts[m].append(layouts[l])
            while m >= 0 {
                trickCombinations[m] += self.layouts[l].combinations
                m -= 1
            }

        }
        /* TODO:  Maybe???  Maybe not???
        for i in leadDeals.indices {
            leadDeals[i].sort(by: { $0.combinations > $1.combinations })
        }
         */
        return LeadStatistics(leadPlan: leads[leadIndex], maxTrickCombinations: trickCombinations, layouts: leadLayouts, maxTricksThisLayout: thisLayoutMaxTricks[leadIndex], trickSequence: trickSequences[leadIndex])
    }
    
    internal func generateAnalysis() -> LayoutAnalysis {
        if leads.count != trickSequences.count || leads.count != maxTricks.count || maxTricks[0].count != layouts.count {
            fatalError("Something incorrect with LayoutAnalyzer state")
        }
        var leadStats: [LeadStatistics] = []
        for i in self.leads.indices {
            leadStats.append(self.statsFor(leadIndex: i))
            assert(leadStats.last?.maxTrickCombinations[0] == combinations)
        }
        let maxTricksThisLayout = leadStats.reduce(0) { max($0, $1.maxTricksThisLayout) }
        let maxTricksAllLayouts = leadStats.reduce(0) { max($0, $1.maxTricksAnyLayout) }
        return LayoutAnalysis(suitLayoutId: suitHolding.initialLayout.id, totalCombinations: combinations, worstCaseTricks: worstCaseTricks, maxTricksThisLayout: maxTricksThisLayout, maxTricksAllLayouts: maxTricksAllLayouts, leads: leadStats)
    }
}
