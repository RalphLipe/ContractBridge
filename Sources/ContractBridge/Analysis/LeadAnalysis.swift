//
//  LeadAnalysis.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


// TODO:  I am not sure this is correct.  In fact I think it is not.
public struct WorstCaseAnalysis {
    private let suitHolding: SuitHolding
    private let maxTricks: Int
    private let shortSide: Position
    private let longSide: Position
    
    private init(suitLayout: SuitLayout, pair: PairPosition) {
        suitHolding = SuitHolding(suitLayout: suitLayout)
        let positions = pair.positions
        let count0 = suitHolding[positions.0].count
        let count1 = suitHolding[positions.1].count
        if count0 < count1 {
            shortSide = positions.0
            longSide = positions.1
            maxTricks = count1
        } else {
            shortSide = positions.1
            longSide = positions.0
            maxTricks = count0
        }
    }
    
    // Play the specified range from position and lowest possible from all other positions
    private func play(range: CompositeRankRange, position: Position) {
        _ = range.lowest().play()
        var playPosition = position.next
        while playPosition != position {
            // TODO: Optimization is a "hasRanks" that bails out with "True" instead of computing count....
            if suitHolding[playPosition].count > 0 {
                _ = suitHolding[playPosition].lowest().play()
            }
            playPosition = playPosition.next
        }
    }
    
    private func minimumTricks() -> Int {
        var numWinners = 0
        // First analyze playing from short side first until we run out of cards
        while suitHolding[shortSide].count > 0 {
            let shortChoices = suitHolding.choices(shortSide)
            if let winShortSide = shortChoices.win {
                play(range: winShortSide, position: shortSide)
                numWinners += 1
            } else {
                let longChoices = suitHolding.choices(longSide)
                if let winLongSide = longChoices.win {
                    play(range: winLongSide, position: longSide)
                    numWinners += 1
                } else {
                    play(range: suitHolding[shortSide], position: shortSide)
                }
            }
        }
        while suitHolding[longSide].count > 0 && numWinners < maxTricks {
            let choices = suitHolding.choices(longSide)
            if let winners = choices.win {
                if numWinners + winners.count == maxTricks {
                    numWinners = maxTricks
                } else {
                    play(range: winners, position: longSide)
                    numWinners += 1
                }
            } else {
                play(range: choices.all.first!, position: longSide)
            }
        }
        return numWinners
    }
    
    public static func minimumTricks(suitLayout: SuitLayout, pair: PairPosition) -> Int {
        return WorstCaseAnalysis(suitLayout: suitLayout, pair: pair).minimumTricks()
    }
    
    public static func isAllWinners(suitLayout: SuitLayout, pair: PairPosition) -> Bool {
        let analysis = WorstCaseAnalysis(suitLayout: suitLayout, pair: pair)
        return analysis.minimumTricks() == analysis.maxTricks
    }
}



public struct TrickSequence {
    public let winningPosition: Position
    public let play: [Position: ClosedRange<Rank>]
}

public struct LayoutCombinations {
    public let layoutId: SuitLayoutIdentifier
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
        return Double(combinationsFor(desiredTricks: desiredTricks)) / Double(maxTrickCombinations[0]) * 100.0
    }
}


public struct LayoutAnalysis {
    public let suitLayoutId: SuitLayoutIdentifier
    public let totalCombinations: Int
    public let worstCaseTricks: Int
    public let maxTricksThisLayout: Int
    public let maxTricksAllLayouts: Int
    public let leads: [LeadStatistics]
    public let exactTrickLayouts: [[LayoutCombinations]]
    
    
    public func bestLeads() -> [LeadStatistics] {
        return bestLeads(desiredTricks: maxTricksAllLayouts)
    }
    
    // NOTE: This returns the double-dummy making statistics.  Maybe a bool for only best leads???
    // TODO:  Figure out non-double dummy stuf
    public func combinationsMaking(_ numberOfTricks: Int) -> Int {
        var desiredTricks = numberOfTricks
        var combinations = 0
        while desiredTricks <= maxTricksAllLayouts {
            combinations = exactTrickLayouts[desiredTricks].reduce(combinations) { $0 + $1.combinations }
            desiredTricks += 1
        }
        return combinations
    }
    
    // TODO: Same thing here -- this is double dummy odds.  Need real odds
    public func percentageMaking(_ numberOfTricks: Int) -> Double {
        return Double(combinationsMaking(numberOfTricks)) / Double(totalCombinations) * 100.0
    }
    
    public func bestOddsCombinationsMaking(_ numberOfTricks: Int) -> Int {
        let bestLeads = bestLeads(desiredTricks: numberOfTricks)
        return bestLeads.first!.combinationsFor(desiredTricks: numberOfTricks)
        
    }
    public func bestOddsPercentageMaking(_ numberOfTricks: Int) -> Double {
        return Double(bestOddsCombinationsMaking(numberOfTricks)) / Double(totalCombinations) * 100.0
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
        // TODO:  This seems incorrect for subsequent analysis since initial layout is used here.  Seems
        // like we need to get the "worstCase" really from the remaining cards.  
        self.worstCaseTricks = WorstCaseAnalysis.minimumTricks(suitLayout: suitHolding.initialLayout, pair: .ns)
        self.layouts = []
        self.thisLayoutMaxTricks = []
        self.trickSequences = []
        self.maxTricks = Array<[Int]>(repeating: [], count: leads.count)

        self.combinations = 0
    }
  /*
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
    */
    
    internal func recordResults(_ results: [Int], layoutId: SuitLayoutIdentifier, combinations: Int) -> Void {
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
   
        return LeadStatistics(leadPlan: leads[leadIndex], maxTrickCombinations: trickCombinations, layouts: leadLayouts, maxTricksThisLayout: thisLayoutMaxTricks[leadIndex], trickSequence: trickSequences[leadIndex])
    }
    
    internal func findExactTrickLayouts(maxTricks: Int) -> [[LayoutCombinations]] {
        var exactLayouts: [[LayoutCombinations]] = []
        var tricksNeeded = 0
        while tricksNeeded <= maxTricks {
            var thisCount = Array<LayoutCombinations>()
       //     if tricksNeeded > worstCaseTricks {
                for y in layouts.indices {
                    var maxThisLayout = 0
                    for x in leads.indices {
                        maxThisLayout = max(maxThisLayout, self.maxTricks[x][y])
                        if maxThisLayout > tricksNeeded { break }
  
                    }
                    if maxThisLayout == tricksNeeded {

                        thisCount.append(self.layouts[y])
                    }
                }
        //    }
            thisCount.sort { $0.combinations > $1.combinations }
            exactLayouts.append(thisCount)
            tricksNeeded += 1
        }
        return exactLayouts
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
        let exactTrickLayouts = findExactTrickLayouts(maxTricks: maxTricksAllLayouts)
        // TODO: Maks worst case tricks = first exactTrickLayouts that is non-zero.  But maybe not...
        
        return LayoutAnalysis(suitLayoutId: suitHolding.initialLayout.id, totalCombinations: combinations, worstCaseTricks: worstCaseTricks, maxTricksThisLayout: maxTricksThisLayout, maxTricksAllLayouts: maxTricksAllLayouts, leads: leadStats, exactTrickLayouts: exactTrickLayouts)
    }
}
