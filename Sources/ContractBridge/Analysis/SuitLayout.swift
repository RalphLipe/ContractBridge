//
//  SuitLayout.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public typealias SuitLayoutIdentifier = Int

public struct SuitLayout {
    private var rankPositions: [Position?]
    
    public var isFullLayout: Bool {
        for position in rankPositions {
            if position == nil { return false }
        }
        return true
    }
    
    public struct PairRange {
        let pair: Pair?
        let range: ClosedRange<Rank>
    }
    
    public var id: SuitLayoutIdentifier {
        return (rankPositions.reversed().reduce(0) { return ($0 * 5) + ($1 == nil ? 0 : 1 + $1!.rawValue) })
    }
    
    public init() {
        self.rankPositions = Array<Position?>(repeating: nil, count: Rank.allCases.count)
    }

    public init(_ from: SuitLayout) {
        self.rankPositions = from.rankPositions
    }

    public init(suitHolding: SuitHolding) {
        self.init()
        for position in Position.allCases {
            for rank in suitHolding[position].ranks {
                self[rank] = position
            }
        }
    }

    public init(suitLayoutId: SuitLayoutIdentifier) {
        self.init()
        var id = suitLayoutId
        for rank in Rank.allCases {
            let val = id % 5
            self[rank] = val == 0 ? nil : Position(rawValue: val - 1)
            id /= 5
        }
    }
    
    public init(deal: Deal, suit: Suit) {
        self.init()
        for position in Position.allCases {
            setRanks(deal[position].ranksFor(suit), position: position)
        }
    }
    
    public mutating func assignNilPositions(_ position: Position) {
        for rank in Rank.allCases {
            if self[rank] == nil { self[rank] = position }
        }
    }
    
    public mutating func setRanks(_ ranks: Set<Rank>, position: Position?) {
        ranks.forEach { self[$0] = position }
    }
    
    /*  TODO: Is this used anywhere?  Seems kinda random. Put it back if useful
    public func toDeal(suit: Suit) -> Deal {
        var deal = Deal()
        for position in Position.allCases {
            deal[position] = Set(ranksFor(position: position).map { Card($0, suit) })
        }
        return deal
    }
     */
    
    public subscript(rank: Rank) -> Position? {
        get { return rankPositions[rank.rawValue] }
        set { rankPositions[rank.rawValue] = newValue }
    }
    
    public func ranksFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Set<Rank> {
        var ranks = Set<Rank>()
        _range.forEach { if self[$0] == position { ranks.insert($0) } }
        return ranks
    }
    
    public func countFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Int {
        return _range.reduce(0) { self[$1] == position ? $0 + 1 : $0}
    }
    
    public mutating func reassignRanks(pairs: Set<Pair> = [.ns, .ew], random: Bool) {
        for pairRange in pairRanges() {
            if let rangePair = pairRange.pair,
                pairs.contains(rangePair) {
                let positions = rangePair.positions
                var count0 = ranksFor(position: positions.0, in: pairRange.range).count
                var count1 = ranksFor(position: positions.1, in: pairRange.range).count
                var ranks = pairRange.range.map { $0 }
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
        var lastPair: Pair? = self[.two]?.pair
        for rank in Rank.three...Rank.ace {
            let thisPair = self[rank]?.pair
            if thisPair == lastPair {
                rangeUpper = rank
            } else {
                ranges.append(PairRange(pair: lastPair, range: rangeLower...rangeUpper))
                rangeLower = rank
                rangeUpper = rank
                lastPair = thisPair
            }
        }
        ranges.append(PairRange(pair: lastPair, range: rangeLower...rangeUpper))
        return ranges
    }
    
}

// TODO:  This is ugly.  Make is nicer...
extension SuitLayout: CustomStringConvertible {
    public var description: String {
        var result = ""
        for position in Position.allCases {
            result += "\(position.shortDescription): \(ranksFor(position: position).description)"
            if position != Position.west { result += " "}
        }
        return result
    }
}
