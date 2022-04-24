//
//  SuitLayout.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public typealias SuitLayoutIdentifier = Int

public struct SuitLayout {
    public let suit: Suit
    internal var rankPositions: [Position]
    
    public struct PairRange {
        let pair: PairPosition
        let ranks: ClosedRange<Rank>
    }
    
    public var id: SuitLayoutIdentifier {
        return (rankPositions.reversed().reduce(0) { return ($0 * 4) + $1.rawValue }) * 4 + suit.rawValue
    }
    
    public func clone() -> SuitLayout {
        return SuitLayout(suit: suit, rankPositions: rankPositions)
    }
    private init(suit: Suit, rankPositions: [Position]) {
        self.suit = suit
        self.rankPositions = rankPositions
        assert(rankPositions.count == Rank.allCases.count)
    }
    
    public init(suitLayoutId: SuitLayoutIdentifier) {
        var id = suitLayoutId
        suit = Suit(rawValue: id % 4)!
        rankPositions = []
        for _ in Rank.allCases {
            id /= 4     // Do this first to get rid of suit
            rankPositions.append(Position(rawValue: id % 4)!)
        }
    }
    
    internal mutating func setRanks(_ ranks: Set<Rank>, position: Position) {
        ranks.forEach { self[$0] = position }
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>, east: Set<Rank>, west: Set<Rank>) {
        assert(north.union(south).union(east).union(west).count == Rank.allCases.count)
        self.suit = suit
        self.rankPositions = Array(repeating: .north, count: Rank.allCases.count)
        setRanks(north, position: .north)
        setRanks(south, position: .south)
        setRanks(east, position: .east)
        setRanks(west, position: .west)
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>) {
        let allRemaining = Set(Rank.allCases).subtracting(north.union(south))
        self.init(suit: suit, north: north, south: south, east: allRemaining, west: [])
    }
    
    public func toDeal() -> Deal {
        var deal = Deal()
        for position in Position.allCases {
            deal[position] = Set(ranksFor(position: position).map { Card($0, suit) })
        }
        return deal
    }
    
    public subscript(rank: Rank) -> Position {
        get { return rankPositions[rank.rawValue] }
        set { rankPositions[rank.rawValue] = newValue }
    }
    
    public func ranksFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Set<Rank> {
        var ranks = Set<Rank>()
        _range.forEach { if self[$0] == position { ranks.insert($0) } }
        return ranks
    }
    
    public mutating func reassignRanks(pairs: Set<PairPosition> = [.ns, .ew], random: Bool) {
        for range in pairRanges() {
            if pairs.contains(range.pair) {
                let positions = range.pair.positions
                var count0 = ranksFor(position: positions.0, in: range.ranks).count
                var count1 = ranksFor(position: positions.1, in: range.ranks).count
                var ranks = range.ranks.map { $0 }
                assert(ranks.count == count0 + count1)
                if random { ranks.shuffle() }
                while count0 > 0 {
                    self[ranks.removeFirst()] = positions.0
                    count0 -= 1
                }
                while count1 > 0 {
                    self[ranks.removeFirst()] = positions.1
                    count1 -= 1
                }
                
            }
        }
    }
    
    public func pairRanges() -> [PairRange] {
        var ranges = Array<PairRange>()
        var rangeLower = Rank.two
        var rangeUpper = Rank.two
        var lastPair = self[.two].pairPosition
        for rank in Rank.three...Rank.ace {
            let thisPair = self[rank].pairPosition
            if thisPair == lastPair {
                rangeUpper = rank
            } else {
                ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
                rangeLower = rank
                rangeUpper = rank
                lastPair = thisPair
            }
        }
        ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
        return ranges
    }
}
