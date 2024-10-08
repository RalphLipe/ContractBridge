//
//  VariableRankPositions.swift
//  
//
//  Created by Ralph Lipe on 9/5/22.
//

import Foundation


public struct VariableRankPositions: Hashable, Equatable {
    public struct PairCounts: Equatable, Hashable {
        public var count0: Int
        public var count1: Int
        public var count: Int { return count0 + count1 }
        public init(count0: Int = 0, count1: Int = 0) {
            self.count0 = count0
            self.count1 = count1
        }
        public subscript(position: Direction) -> Int {
            get {
                return position.pairDirection.directions.0 == position ? count0 : count1
            }
            set {
                assert(newValue >= 0)
                if position.pairDirection.directions.0 == position {
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


    
    
    public struct Bracket: Equatable, Hashable {
        public var pair: PairDirection
        public var upperBound: Rank
        public var known: PairCounts
        public var unknownCount: Int = 0
        
        public init(pair: PairDirection, upperBound: Rank, known: PairCounts, unknownCount: Int) {
            self.pair = pair
            self.upperBound = upperBound
            self.known = known
            self.unknownCount = unknownCount
        }
        
        public var count: Int {
            return known.count + unknownCount
        }
        
        public func knownCount(_ position: Direction) -> Int {
            return pair == position.pairDirection ? known[position] : 0
        }
        
        internal func combinations(for pair: PairDirection) -> Int {
            return self.pair == pair ? (1 << unknownCount) : 1
        }
    }
    
    
    
    // THis needs to be contained in VariableRankPositions...
    public struct Variant: Equatable, Hashable {
        // TODO: Document this:
        public struct Bracket: Equatable, Hashable {
            public var pair: PairDirection
            public var upperBound: Rank
            public var known: PairCounts
            public var unknown: PairCounts
            public var count: Int { return known.count + unknown.count }
            
            public init(pair: PairDirection, upperBound: Rank, known: PairCounts, unknown: PairCounts) {
                self.pair = pair
                self.upperBound = upperBound
                self.known = known
                self.unknown = unknown
                assert(unknown.count0 >= 0)
                assert(unknown.count1 >= 0)
            }
            
            public func count(_ position: Direction) -> Int {
                return pair == position.pairDirection ? known[position] + unknown[position] : 0
            }
            
            var variableBracket: VariableRankPositions.Bracket {
                return VariableRankPositions.Bracket(pair: pair, upperBound: upperBound, known: known, unknownCount: unknown.count)
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
            
            internal func combinations(for pair: PairDirection) -> Int {
                return self.pair == pair ? combinations(n: unknown.count, r: unknown.count0) : 1
            }
            
            internal mutating func play(_ rank: Rank, from position: Direction) {
                if pair != position.pairDirection { fatalError() }
                if known[position] > 0 {
                    known[position] -= 1
                } else {
                    assert(unknown[position] > 0)
                    unknown[position] -= 1
                }
            }
            
            internal mutating func merge(with other: Bracket) {
                assert(pair == other.pair)
                assert(upperBound > other.upperBound)
                known += other.known
                unknown += other.unknown
            }
            
            internal mutating func setAllKnown(in position: Direction) {
                if pair == position.pairDirection {
                    known[position] += unknown[position]
                    unknown[position] = 0
                    assert(count(position.partner) == 0)
                }
            }
        }

        
        public var brackets: [Variant.Bracket]
        public let variablePair: PairDirection
        
        public func ranks(for position: Direction) -> RankSet {
            return brackets.reduce(into: RankSet()) { if $1.count(position) > 0 { $0.insert($1.upperBound) }}
        }
        
        public func holdsRanks(_ pair: PairDirection) -> Bool {
            for bracket in brackets {
                if bracket.pair == pair && bracket.count > 0 {
                    return true
                }
            }
            return false
        }

        public var combinations: Int {
            return brackets.reduce(1) { $0 * $1.combinations(for: variablePair) }
        }
        
        private func index(_ rank: Rank) -> Array<Bracket>.Index {
            return brackets.firstIndex(where: {$0.upperBound >= rank} )!
        }

        private mutating func play(_ rank: Rank?, from position: Direction) {
            if let rank = rank {
                brackets[index(rank)].play(rank, from: position)
            }
        }
        
        private mutating func compact() {
            var i = 0
            while i < brackets.count {
                if brackets[i].count == 0 {
                    brackets.remove(at: i)
                    if brackets.count > 0 {
                        if i == brackets.count {
                            brackets[i - 1].upperBound = .ace
                        } else if i > 0 {
                            // This is a mid-range merge.
                            assert(brackets[i].pair == brackets[i-1].pair)
                            brackets[i].merge(with: brackets[i-1])
                            brackets.remove(at: i-1)
                        }
                    }
                } else {
                    i += 1
                }
            }
            assert(brackets.count == 0 || brackets.last!.upperBound == .ace)
        }
        
        private mutating func allKnown(in position: Direction) {
            for i in brackets.indices {
                brackets[i].setAllKnown(in: position)
            }
        }
        
        private mutating func internalPlay(leadPosition: Direction, play: PositionRanks, finesseInferences: Bool) {
            guard let winning = play.winning else { fatalError() }
            // First we will mark any inticated ranks as know for the variable pair.
            // If one side or the other shows out then all ranks are known to be in the partner position
            let varPos = variablePair.directions
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
                            for i in brackets.indices {
                                if brackets[i].upperBound > thirdHand && brackets[i].upperBound < winning.rank && brackets[i].pair == variablePair {
                                    brackets[i].setAllKnown(in: leadPosition.next)
                                }
                            }
                        }
                    }
                    // It is possible that a range is marked by a double finesse...  If
                } else if winning.position.pairDirection == leadPosition.pairDirection  {
                    // TODO: Really?  Is this logic right?  Could both sides duck?  Right now only 2nd seat ducks
                    // Since the lead pair won, then any higher ranks than the winning one must be in 2nd position
                    if winning.rank < .ace {
                        for i in brackets.indices {
                            if brackets[i].upperBound > winning.rank && brackets[i].pair == variablePair {
                                brackets[i].setAllKnown(in: leadPosition.next)
                            }
                        }
                    }
                    // Now any cards in opponents that are in lower brackets than the card played must belong to
                    // the other opponent.  If a Q drops, the partner of the dropper has the lower cards.
                    // TODO: This is incomplete since it could be won by 3rd hand. More issues with that though, since
                    // play could be a finesse.  Need to think this through.  Perhaps pass lead into this method?
                    if winning.position == leadPosition {
                        let opponents = leadPosition.pairDirection.opponents.directions
                        markLowerRanks(opponents.0, play[opponents.0])
                        markLowerRanks(opponents.1, play[opponents.1])
                    }
                }
            }
            Direction.allCases.forEach { self.play(play[$0], from: $0) }
            compact()
        }
        
        private mutating func markLowerRanks(_ position: Direction, _ played: Rank?) {
            if let rank = played {
                var i = index(rank)
                while i > 0 {
                    i -= 1
                    if brackets[i].pair == position.pairDirection {
                        brackets[i].setAllKnown(in: position.partner)
                    }
                }
            }
        }
        
        public func play(leadPosition: Direction, play: PositionRanks, finesseInferences: Bool = true) -> Variant {
            var next = self
            next.internalPlay(leadPosition: leadPosition, play: play, finesseInferences: finesseInferences)
            return next
        }
        
        
        internal func fillRanks(in layout: inout RankPositions, count: Int, position: Direction, rank: inout Rank) -> Void {
            var c = count
            while c > 0 {
                layout[rank] = position
                c -= 1
                let nextRank = rank.nextLower
                if let nextRank = nextRank {
                    rank = nextRank
                } else {
                    assert(c == 0)
                }
            }
        }
        
        public var representativeLayout: RankPositions {
            var result = RankPositions()
            for bracket in brackets {
                let positions = bracket.pair.directions
                var rank = bracket.upperBound
                fillRanks(in: &result, count: bracket.count(positions.0), position: positions.0, rank: &rank)
                fillRanks(in: &result, count: bracket.count(positions.1), position: positions.1, rank: &rank)
            }
            return result
        }
        
        public func upperBound(rank: Rank, pair: PairDirection) -> Rank {
            return brackets[index(rank)].upperBound
        }
        
        public func rangeOf(_ rank: Rank?) -> RankRange? {
            guard let rank = rank else { return nil }
            let i = index(rank)
            let lowerBound: Rank = i == 0 ? .two : brackets[i-1].upperBound.nextHigher!
            return lowerBound...brackets[i].upperBound
        }
    }

    
    public var brackets: [Bracket] = []
    public let variablePair: PairDirection
    
    public static func == (lhs: VariableRankPositions, rhs: VariableRankPositions) -> Bool {
        return lhs.brackets == rhs.brackets && lhs.variablePair == rhs.variablePair
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(variablePair)
        hasher.combine(brackets)
    }
    
    private func pair(for rank: Rank, in holding: RankPositions) -> PairDirection {
        if let position = holding[rank] {
            return position.pairDirection
        } else {
            return variablePair
        }
    }
    
    public init(from variant: Variant) {
        self.brackets = variant.brackets.map { VariableRankPositions.Bracket(pair: $0.pair, upperBound: $0.upperBound, known: $0.known, unknownCount: $0.unknown.count) }
        self.variablePair = variant.variablePair
    }
    
    public func ranks(for position: Direction) -> RankSet {
        assert(variablePair != position.pairDirection)
        return brackets.reduce(into: RankSet()) { if $1.knownCount(position) > 0 { $0.insert($1.upperBound) }}
    }

    
    public var loserUpperBound: Rank {
        return brackets[0].upperBound
    }

    
    public func count(for position: Direction) -> Int {
        assert(variablePair != position.pairDirection)
        return brackets.reduce(0) { return $0 + $1.knownCount(position) }
    }
    
    public init(partialHolding: RankPositions, variablePair: PairDirection = .ew) {
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
            brackets.append(Bracket(pair: pair, upperBound: rank, known: known, unknownCount: unknownCount))
            guard let next = rank.nextHigher else { break }
            rank = next
        }
    }
    
    
    
    
    public var combinations: Int {
        return brackets.reduce(1) { return $0 * $1.combinations(for: variablePair) }
    }
    
    private class VariantBuilder {
        private let variableRankPositions: VariableRankPositions
        private var brackets: [Variant.Bracket]
        private var variants: [Variant] = []
        
        init(_ variableRankPositions: VariableRankPositions) {
            self.variableRankPositions = variableRankPositions
            self.brackets = variableRankPositions.brackets.map { return Variant.Bracket(pair: $0.pair, upperBound: $0.upperBound, known: $0.known, unknown: PairCounts()) }
            createVariant(index: 0)
        }
        
        internal static func variants(for variableRankPositions: VariableRankPositions) -> [Variant] {
            return VariantBuilder(variableRankPositions).variants
        }
        
        private func createVariant(index: Int) {
            if index >= brackets.count {
                variants.append(Variant(brackets: brackets, variablePair: variableRankPositions.variablePair))
            } else {
                let unknown = variableRankPositions.brackets[index].unknownCount
                var count0 = 0
                // NOTE: This look will always execute once even if unknown == 0
                while count0 <= unknown {
                    brackets[index].unknown.count0 = count0
                    brackets[index].unknown.count1 = unknown - count0
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
 
    

//====================================== NEW DOUBLE DUMMY STUFF

public class DoubleDummy {
    public var variant: VariableRankPositions.Variant
    public let leads: [LeadPlan]
    public init (holding: VariableRankPositions, variant: VariableRankPositions.Variant) {
        self.variant = variant
        self.leads = LeadGenerator.generateLeads(holding: holding, pair: .ns, option: .considerAll)
    }
}
