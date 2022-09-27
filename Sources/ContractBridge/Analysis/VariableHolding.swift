//
//  File.swift
//  
//
//  Created by Ralph Lipe on 9/5/22.
//

import Foundation
import AppKit

public struct KnownHoldings {
    var rank: Rank
    let pair: Pair
    var count0: Int = 0
    var count1: Int = 0
    public init(rank: Rank, pair: Pair) {
        self.rank = rank
        self.pair = pair
    }
    var count: Int { return count0 + count1 }
}

public struct VariableXXX {
    var known: KnownHoldings
    var unknownCount: Int = 0
    
    public var count: Int {
        return known.count + unknownCount
    }
    
    internal func combinations(for pair: Pair) -> Int {
        return known.pair == pair ? (1 << count) : 1
    }
}

public struct XXXCombination {
    var known: KnownHoldings
    var unknownCount0: Int = 0
    var unknownCount1: Int = 0
    var unknownCount: Int { return unknownCount0 + unknownCount1 }
    var count: Int { return known.count + unknownCount }
    
    func count(for position: Position) -> Int {
        if known.pair != position.pair { return 0 }
        return position == known.pair.positions.0 ? known.count0 + unknownCount0 : known.count1 + unknownCount1
    }
    
    var variableXXX: VariableXXX {
        return VariableXXX(known: known, unknownCount: unknownCount)
    }
    
    // Standard math factorial
    private func factorial(_ n: Int) -> Int {
        assert(n >= 0)
        return n <= 1 ? 1 : n * factorial(n - 1)
    }
    
    // Computes the combinations of n items placed into r positions.  Google "Combinations Formula" for more info.
    private func combinations(n: Int, r: Int) -> Int {
        assert(n >= r)
        return (r == 0 || r == n) ? 1 : factorial(n) / (factorial(r) * factorial(n - r))
    }
    
    internal func combinations(for pair: Pair) -> Int {
        return known.pair == pair ? (1 << known.count) * combinations(n: unknownCount, r: unknownCount0) : 1
    }

    internal mutating func play(_ rank: Rank, from position: Position) {
        if known.pair != position.pair { fatalError() }
        if known.pair.positions.0 == position {
            if known.count0 > 0 {
                known.count0 -= 1
            } else {
                assert(unknownCount0 > 0)
                unknownCount0 -= 1
            }
        } else {
            if known.count1 > 0 {
                known.count1 -= 1
            } else {
                assert(unknownCount1 > 0)
                unknownCount1 -= 1
            }
        }
    }
    
    internal mutating func merge(with other: XXXCombination) {
        assert(known.pair == other.known.pair)
        assert(known.rank > other.known.rank)
        known.count0 += other.known.count0
        known.count1 += other.known.count1
        unknownCount0 += other.unknownCount0
        unknownCount1 += other.unknownCount1
    }
    
    internal mutating func allKnown(in position: Position) {
        if known.pair == position.pair {
            if position == known.pair.positions.0 {
                known.count0 += unknownCount0
                unknownCount0 = 0
                assert(unknownCount1 == 0)
            } else {
                known.count1 += unknownCount1
                unknownCount1 = 0
                assert(unknownCount0 == 0)
            }
        }
    }
    
}

public struct VariableHolding {
    private var ranges: [VariableXXX] = []
    private let variablePair: Pair
    
    private func pair(for rank: Rank, in holding: RankPositions) -> Pair {
        if let position = holding[rank] {
            return position.pair
        } else {
            return variablePair
        }
    }
    
    public init(from vc: VariableCombination) {
        self.ranges = vc.ranges.map { $0.variableXXX }
        self.variablePair = vc.variablePair
    }
    
    public init(partialHolding: RankPositions, variablePair: Pair = .ew) {
        self.variablePair = variablePair
        
        var rank = Rank.two
        while true {
            let pair = pair(for: rank, in: partialHolding)
            var known = KnownHoldings(rank: rank, pair: pair)
            var unknownCount = 0
            let positions = pair.positions
            while true {
                if let position = partialHolding[rank] {
                    if position == positions.0 {
                        known.count0 += 1
                    } else {
                        assert(position == positions.1)
                        known.count1 += 1
                    }
                } else {
                    assert(pair == variablePair)
                    unknownCount += 1
                }
                guard let next = rank.nextHigher else { break }
                if pair != self.pair(for: next, in: partialHolding) { break }
                rank = next
            }
            known.rank = ranges.count == 0 ? .two : rank
            ranges.append(VariableXXX(known: known, unknownCount: unknownCount))
            guard let next = rank.nextHigher else { break }
            rank = next
        }
    }
    
    
    
    
    public var combinations: Int {
        return ranges.reduce(1) { return $0 * $1.combinations(for: variablePair) }
    }
    
    private class ComboBuilder {
        private let variableHolding: VariableHolding
        private var ranges: [XXXCombination]
        private var combos: [VariableCombination] = []
        
        init(_ variableHolding: VariableHolding) {
            self.variableHolding = variableHolding
            self.ranges = variableHolding.ranges.map { return XXXCombination(known: $0.known) }
            createCombo(index: 0)
        }
        
        internal static func combos(for variableHolding: VariableHolding) -> [VariableCombination] {
            return ComboBuilder(variableHolding).combos
        }
        
        private func createCombo(index: Int) {
            if index >= ranges.count {
                combos.append(VariableCombination(ranges: ranges, variablePair: variableHolding.variablePair))
            } else {
                let unknown = variableHolding.ranges[index].unknownCount
                var count0 = 0
                // NOTE: This look will always execute once even if unknown == 0
                while count0 <= unknown {
                    ranges[index].unknownCount0 = count0
                    ranges[index].unknownCount1 = unknown - count0
                    createCombo(index: index + 1)
                    count0 += 1
                }
            }
        }
    }
    
    public func combinationHoldings() -> [VariableCombination] {
        return ComboBuilder.combos(for: self)
    }
    
}

public struct VariableCombination {
    public var ranges: [XXXCombination]
    public let variablePair: Pair
    
    public func ranks(for position: Position) -> RankSet {
        return ranges.reduce(into: RankSet()) { if $1.count(for: position) > 0 { $0.insert($1.known.rank) }}
    }
    
    // Standard math factorial
    private static func factorial(_ n: Int) -> Int {
        assert(n >= 0)
        return n <= 1 ? 1 : n * factorial(n - 1)
    }
    
    // Computes the combinations of n items placed into r positions.  Google "Combinations Formula" for more info.
    private static func combinations(n: Int, r: Int) -> Int {
        assert(n >= r)
        return (r == 0 || r == n) ? 1 : factorial(n) / (factorial(r) * factorial(n - r))
    }
    
    public var combinations: Int {
        var c = 1
        for range in ranges {
            if range.known.pair == variablePair {
                c *= 1 << range.known.count
                c *= Self.combinations(n: range.unknownCount, r: range.unknownCount0)
            }
        }
        return c
    }
    
    private mutating func play(_ rank: Rank?, from position: Position) {
        if let rank = rank {
            guard let i = ranges.firstIndex(where: { $0.known.rank == rank }) else { fatalError() }
            ranges[i].play(rank, from: position)
            if ranges[i].count == 0 {
                ranges.remove(at: i)
                if ranges.count > 0 {
                    if i == ranges.count - 1 {
                        ranges[i - 1].known.rank = .ace
                    } else if i == 0 {
                        ranges[i].known.rank = .two
                    } else {
                        ranges[i].merge(with: ranges[i-1])
                        if i == 1 { ranges[i].known.rank = .two }
                        ranges.remove(at: i-1)
                    }
                }
            }
        }
    }
    
    private mutating func allKnown(in position: Position) {
        for i in ranges.indices {
            ranges[i].allKnown(in: position)
        }
    }
    
    private mutating func internalPlay(leadPlan: LeadPlan, play: PositionRanks) {
        guard let winning = play.winning else { fatalError() }
        // First we will mark any inticated ranks as know for the variable pair.
        // If one side or the other shows out then all ranks are known to be in the partner position
        let varPos = variablePair.positions
        if play[varPos.0] == nil {
            if play[varPos.1] != nil {
                allKnown(in: varPos.1)
            }
        } else {
            if play[varPos.1] == nil {
                allKnown(in: varPos.0)
            }
        }
        // TODO: If one nil then nothing left to do...
        // TODO: Mark ranges as known based on play:  2nd position if N/S wins or if E/W wins double finesse
        if winning.position == leadPlan.position.previous { // If 4th seat wins then check for marked 2nd position ranks
            if let thirdHand = play[leadPlan.position.partner] {
                if thirdHand > play[leadPlan.position]! {
                    for i in ranges.indices {
                        if ranges[i].known.rank > thirdHand && ranges[i].known.rank < winning.rank && ranges[i].known.pair == variablePair {
                            ranges[i].allKnown(in: leadPlan.position.next)
                        }
                    }
                }
            }
            // It is possible that a range is marked by a double finesse...  If
        } else {
            // TODO: Really?  Is this logic right?  Could both sides duck?  Right now only 2nd seat ducks
            // Since the lead pair won, then any higher ranks than the winning one must be in 2nd position
            if winning.rank < .ace {
                for i in ranges.indices {
                    if ranges[i].known.rank > winning.rank && ranges[i].known.pair == variablePair {
                        ranges[i].allKnown(in: leadPlan.position.next)
                    }
                }
            }
        }
        Position.allCases.forEach { self.play(play[$0], from: $0) }
    }
    
    public func play(leadPlan: LeadPlan, play: PositionRanks) -> VariableHolding {
        var next = self
        next.internalPlay(leadPlan: leadPlan, play: play)
        return VariableHolding(from: next)
    }
}
    
    

public struct LayoutCombinations {
    public let holding: RankPositions
    public let combinationsRepresented: Int
}

/*
public struct LayoutGenerator {
    private static func assignUnknown(holding: RankPositions, pair: Pair, start: Rank?, unknown: RankSet, combinations: Int, inout layouts: [LayoutCombinations]) -> Void {
        var shiftRanks = RankSet()
        var rank: Rank? = start
        while rank != nil,
              holding[rank!] != pair.opponents {
            if unknown.contains(rank!) {
                shiftRanks.insert(rank!)
            }
            rank = rank?.nextHigher
        }
    }
    
    public static func generateLayouts(known holding: RankPositions, unknown: RankSet, heldBy pair: Pair) -> [LayoutCombinations] {
        var layouts = Array<LayoutCombinations>()
        if unknown.isEmpty {
            layouts.append(LayoutCombinations(holding: holding, combinationsRepresented: 1))
        } else {
            // TODO: Who is the right pair for parameter.  Seems ambiguous...
            Self.shil
        }
        return layouts
    }
}
*/

/*
// TODO: Class or struct?  Seems like class probably
public class CombinationAnalysis {
    // TODO: Cache of child analyses
    //
    
    public static func analyze(holding: RankPositions, onLead: Pair) -> CombinationAnalysis {
        return Self.analyze(partialHolding: holding, onlead: onLead, unknownPositions: RankSet(), heldBy: onLead.opponents)
    }
    
    public static func analyze(partialHolding: RankPositions, onLead: Pair) -> CombinationAnalysis {
        let unknown = RankSet(Rank.allCases).subtracting(partialHolding.ranks)
    }
    
    public static func analyze(partialHolding: RankPositions, onLead: Pair, unknownPositions: RankSet, heldBy: Pair) -> CombinationAnalysis {
        
    }
    
    
    private init(cache: [LayoutCombinations: CombinationAnalysis])
}
 */
