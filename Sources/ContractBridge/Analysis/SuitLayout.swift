//
//  SuitLayout.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public typealias SuitLayoutIdentifier = Int
public typealias SuitLayout = Dictionary<Rank, Position>



public extension Dictionary where Key == Rank, Value == Position {

    init(suitHolding: SuitHolding) {
        self.init()
        for position in Position.allCases {
            for rank in suitHolding[position].ranks {
                self[rank] = position
            }
        }
    }

    init(suitLayoutId: SuitLayoutIdentifier) {
        self.init()
        var id = suitLayoutId
        for rank in Rank.allCases {
            let val = id % 5
            self[rank] = val == 0 ? nil : Position(rawValue: val - 1)
            id /= 5
        }
    }
    
    init(deal: Deal, suit: Suit) {
        self.init()
        for position in Position.allCases {
            assign(ranks: deal.hands[position].ranks(for: suit), position: position)
        }
    }

    var isFullLayout: Bool {
        return count == Rank.allCases.count
    }
    
    var id: SuitLayoutIdentifier {
        var id = 0
        for rank in Rank.allCases.reversed() {
            id *= 5
            if let position = self[rank] {
                id += position.rawValue + 1
            }
        }
        return id
    }

    
    mutating func assignNilPositions(_ position: Position) {
        for rank in Rank.allCases {
            if self[rank] == nil { self[rank] = position }
        }
    }
    
    mutating func assign(ranks: RankSet, position: Position?) {
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
    
    
    func ranksFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> RankSet {
        var ranks = RankSet()
        _range.forEach { if self[$0] == position { ranks.insert($0) } }
        return ranks
    }
    
    func countFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Int {
        return _range.reduce(0) { self[$1] == position ? $0 + 1 : $0}
    }
    
    mutating func reassignRanks(pairs: Set<Pair> = [.ns, .ew], random: Bool) {
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
    
    struct PairRange {
        public let pair: Pair?
        public let range: ClosedRange<Rank>
    }
    
    func pairRanges() -> [PairRange] {
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

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ suitLayout: SuitLayout, style: ContractBridge.Style = .symbol) {
        appendLiteral(Position.allCases.map {
            "\($0, style: style): \(suitLayout.ranksFor(position: $0), style: style)" }.joined(separator: " "))
        
    }
}
