//
//  File.swift
//  
//
//  Created by Ralph Lipe on 9/5/22.
//

import Foundation



public struct PairCounts: Equatable, Hashable {
    public var count0: Int = 0
    public var count1: Int = 0
    public var count: Int { return count0 + count1 }
    public subscript(position: Position) -> Int {
        get {
            return position.pair.positions.0 == position ? count0 : count1
        }
        set {
            assert(newValue >= 0)
            if position.pair.positions.0 == position {
                count0 = newValue
            } else {
                count1 = newValue
            }
        }
    }
    static func +=(lhs: inout PairCounts, rhs: PairCounts) {
        lhs.count0 += rhs.count0
        lhs.count1 += rhs.count1
    }
}

/*
public struct KnownHoldings: Equatable, Hashable {
    public var rank: Rank
    public let pair: Pair
    public var count0: Int = 0
    public var count1: Int = 0
    public init(rank: Rank, pair: Pair) {
        self.rank = rank
        self.pair = pair
    }
    public var count: Int { return count0 + count1 }
    public func count(for position: Position) -> Int {
        if position.pair != pair { return 0 }
        return position == pair.positions.0 ? count0 : count1
    }
}
 */

public struct VariableGroup: Equatable, Hashable {
    public var pair: Pair
    public var upperBound: Rank
    public var known: PairCounts
    public var unknownCount: Int = 0
    
    public init(pair: Pair, upperBound: Rank, known: PairCounts, unknownCount: Int) {
        self.pair = pair
        self.upperBound = upperBound
        self.known = known
        self.unknownCount = unknownCount
    }
    
    public var count: Int {
        return known.count + unknownCount
    }
    
    public func knownCount(_ position: Position) -> Int {
        return pair == position.pair ? known[position] : 0
    }
    
    internal func combinations(for pair: Pair) -> Int {
        return pair == pair ? (1 << unknownCount) : 1
    }
}



// TODO: Document this:
public struct VariantGroup: Equatable, Hashable {
    public var pair: Pair
    public var upperBound: Rank
    public var known: PairCounts
    public var unknown: PairCounts
    public var count: Int { return known.count + unknown.count }
    
    public init(pair: Pair, upperBound: Rank, known: PairCounts, unknown: PairCounts) {
        self.pair = pair
        self.upperBound = upperBound
        self.known = known
        self.unknown = unknown
        assert(unknown.count0 >= 0)
        assert(unknown.count1 >= 0)
    }
    
    public func count(_ position: Position) -> Int {
        return pair == position.pair ? known[position] + unknown[position] : 0
    }
    
    var variableGroup: VariableGroup {
        return VariableGroup(pair: pair, upperBound: upperBound, known: known, unknownCount: unknown.count)
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
        return pair == pair ? combinations(n: unknown.count, r: unknown.count0) : 1
    }

    internal mutating func play(_ rank: Rank, from position: Position) {
        if pair != position.pair { fatalError() }
        if known[position] > 0 {
            known[position] -= 1
        } else {
            assert(unknown[position] > 0)
            unknown[position] -= 1
        }
    }
    
    internal mutating func merge(with other: VariantGroup) {
        assert(pair == other.pair)
        assert(upperBound > other.upperBound)
        known += other.known
        unknown += other.unknown
    }
    
    internal mutating func setAllKnown(in position: Position) {
        if pair == position.pair {
            known[position] += unknown[position]
            unknown[position] = 0
            assert(count(position.partner) == 0)
        }
    }
}

public struct VariableRankPositions: Hashable, Equatable {
    public var groups: [VariableGroup] = []
    public let variablePair: Pair
    
    public static func == (lhs: VariableRankPositions, rhs: VariableRankPositions) -> Bool {
        return lhs.groups == rhs.groups && lhs.variablePair == rhs.variablePair
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(variablePair)
        hasher.combine(groups)
    }
    
    private func pair(for rank: Rank, in holding: RankPositions) -> Pair {
        if let position = holding[rank] {
            return position.pair
        } else {
            return variablePair
        }
    }
    
    public init(from variant: Variant) {
        self.groups = variant.groups.map { VariableGroup(pair: $0.pair, upperBound: $0.upperBound, known: $0.known, unknownCount: $0.unknown.count) }
        self.variablePair = variant.variablePair
    }
    
    public func ranks(for position: Position) -> RankSet {
        assert(variablePair != position.pair)
        return groups.reduce(into: RankSet()) { if $1.knownCount(position) > 0 { $0.insert($1.upperBound) }}
    }

    
    public var loserUpperBound: Rank {
        return groups[0].upperBound
    }

    
    public func count(for position: Position) -> Int {
        assert(variablePair != position.pair)
        return groups.reduce(0) { return $0 + $1.knownCount(position) }
    }
    
    public init(partialHolding: RankPositions, variablePair: Pair = .ew) {
        self.variablePair = variablePair
        
        var rank = Rank.two
        while true {
            let pair = pair(for: rank, in: partialHolding)
            var known = PairCounts()
            var unknownCount = 0
            while true {
                if let position = partialHolding[rank] {
                    known[position] += 1
                } else {
                    assert(pair == variablePair)
                    unknownCount += 1
                }
                guard let next = rank.nextHigher else { break }
                if pair != self.pair(for: next, in: partialHolding) { break }
                rank = next
            }
            groups.append(VariableGroup(pair: pair, upperBound: rank, known: known, unknownCount: unknownCount))
            guard let next = rank.nextHigher else { break }
            rank = next
        }
    }
    
    
    
    
    public var combinations: Int {
        return groups.reduce(1) { return $0 * $1.combinations(for: variablePair) }
    }
    
    private class VariantBuilder {
        private let variableRankPositions: VariableRankPositions
        private var groups: [VariantGroup]
        private var variants: [Variant] = []
        
        init(_ variableRankPositions: VariableRankPositions) {
            self.variableRankPositions = variableRankPositions
            self.groups = variableRankPositions.groups.map { return VariantGroup(pair: $0.pair, upperBound: $0.upperBound, known: $0.known, unknown: PairCounts()) }
            createVariant(index: 0)
        }
        
        internal static func variants(for variableRankPositions: VariableRankPositions) -> [Variant] {
            return VariantBuilder(variableRankPositions).variants
        }
        
        private func createVariant(index: Int) {
            if index >= groups.count {
                variants.append(Variant(groups: groups, variablePair: variableRankPositions.variablePair))
            } else {
                let unknown = variableRankPositions.groups[index].unknownCount
                var count0 = 0
                // NOTE: This look will always execute once even if unknown == 0
                while count0 <= unknown {
                    groups[index].unknown.count0 = count0
                    groups[index].unknown.count1 = unknown - count0
                    createVariant(index: index + 1)
                    count0 += 1
                }
            }
        }
    }
    
    public var variants: [Variant] {
        return VariantBuilder.variants(for: self)
    }
    
}

// THis needs to be contained in VariableRankPositions...
public struct Variant: Equatable, Hashable {
    public var groups: [VariantGroup]
    public let variablePair: Pair
    
    public func ranks(for position: Position) -> RankSet {
        return groups.reduce(into: RankSet()) { if $1.count(position) > 0 { $0.insert($1.upperBound) }}
    }
    
    public func holdsRanks(_ pair: Pair) -> Bool {
        for group in groups {
            if group.pair == pair && group.count > 0 {
                return true
            }
        }
        return false
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
        for group in groups {
            if group.pair == variablePair {
                c *= 1 << group.known.count
                c *= Self.combinations(n: group.unknown.count, r: group.unknown.count0)
            }
        }
        return c
    }
    

    private mutating func play(_ rank: Rank?, from position: Position) {
        if let rank = rank {
            guard let i = groups.firstIndex(where: { $0.upperBound >= rank }) else { fatalError() }
            groups[i].play(rank, from: position)
        }
    }
    
    private mutating func compact() {
        var i = 0
        while i < groups.count {
            if groups[i].count == 0 {
                groups.remove(at: i)
                if groups.count > 0 {
                    if i == groups.count {
                        groups[i - 1].upperBound = .ace
                    } else if i > 0 {
                        // This is a mid-range merge.
                        assert(groups[i].pair == groups[i-1].pair)
                        groups[i].merge(with: groups[i-1])
                        groups.remove(at: i-1)
                    }
                }
            } else {
                i += 1
            }
        }
        // Now if there is a single range make sure it is .ace instead of .two
     //   if groups.count == 1 {
     //       groups[0].coequal.rank = .ace
      //  }
        assert(groups.count != 1 || groups[0].upperBound == .ace)
    }
    
    private mutating func allKnown(in position: Position) {
        for i in groups.indices {
            groups[i].setAllKnown(in: position)
        }
    }
    
    private mutating func internalPlay(leadPosition: Position, play: PositionRanks, finesseInferences: Bool) {
        guard let winning = play.winning else { fatalError() }
        // First we will mark any inticated ranks as know for the variable pair.
        // If one side or the other shows out then all ranks are known to be in the partner position
        let varPos = variablePair.positions
        if play[varPos.0] == nil {
            if play[varPos.1] != nil {
                allKnown(in: varPos.1)
            }
        } else if play[varPos.1] == nil {
            allKnown(in: varPos.0)
        }
        if finesseInferences {
            // TODO: If one nil then nothing left to do...
            // TODO: Mark ranges as known based on play:  2nd position if N/S wins or if E/W wins double finesse
            if winning.position == leadPosition.previous { // If 4th seat wins then check for marked 2nd position ranks
                if let thirdHand = play[leadPosition.partner] {
                    if thirdHand > play[leadPosition]! {
                        for i in groups.indices {
                            if groups[i].upperBound > thirdHand && groups[i].upperBound < winning.rank && groups[i].pair == variablePair {
                                groups[i].setAllKnown(in: leadPosition.next)
                            }
                        }
                    }
                }
                // It is possible that a range is marked by a double finesse...  If
            } else if winning.position.pair == leadPosition.pair  {
                // TODO: Really?  Is this logic right?  Could both sides duck?  Right now only 2nd seat ducks
                // Since the lead pair won, then any higher ranks than the winning one must be in 2nd position
                if winning.rank < .ace {
                    for i in groups.indices {
                        if groups[i].upperBound > winning.rank && groups[i].pair == variablePair {
                            groups[i].setAllKnown(in: leadPosition.next)
                        }
                    }
                }
            }
        }
        Position.allCases.forEach { self.play(play[$0], from: $0) }
        compact()
    }
    
    public func play(leadPosition: Position, play: PositionRanks, finesseInferences: Bool = true) -> Variant {
        var next = self
        next.internalPlay(leadPosition: leadPosition, play: play, finesseInferences: finesseInferences)
        return next
    }
}
    
    


