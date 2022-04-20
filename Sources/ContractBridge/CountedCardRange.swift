//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


public class CountedCardRange: Comparable, CustomStringConvertible {
    public let index: Int
    public let suit: Suit
    public let ranks: ClosedRange<Rank>
    public let pair: PairPosition
    public var count: Int

    init(pair: PairPosition, suit: Suit, ranks: ClosedRange<Rank>, index: Int, count: Int? = nil) {
        self.index = index
        self.suit = suit
        self.ranks = ranks
        self.pair = pair
        self.count = 0
    }
    
    func copy(count: Int? = nil) -> CountedCardRange {
        return CountedCardRange(pair: pair, suit: suit, ranks: ranks, index: index, count: count == nil ? self.count : count)
    }
    
    public static func < (lhs: CountedCardRange, rhs: CountedCardRange) -> Bool {
        return lhs.ranks.upperBound < rhs.ranks.lowerBound
    }
    
    public static func == (lhs: CountedCardRange, rhs: CountedCardRange) -> Bool {
        return lhs.ranks == rhs.ranks
    }
    
    public var description: String {
        if ranks.lowerBound == ranks.upperBound { return ranks.lowerBound.shortDescription }
        return "\(ranks.lowerBound.shortDescription)...\(ranks.upperBound.shortDescription)"
    }
    
    public static func createRanges(from _deal: Deal) -> [Suit:[CountedCardRange]] {
        var nsAllCards = _deal[.north]
        nsAllCards.append(contentsOf: _deal[.south])
        var result: [Suit:[CountedCardRange]] = [:]
        for suit in Suit.allCases {
            let ranks = Set(nsAllCards.filter(by: suit).map { $0.rank })
            var ranges: [CountedCardRange] = []
            var rangeLower = Rank.two
            var rangeUpper = Rank.two
            var pair: PairPosition = ranks.contains(.two) ? .ns : .ew
            for rank in Rank.three...Rank.ace {
                let isNsCard = ranks.contains(rank)
                if (isNsCard && pair == .ns) || (isNsCard == false && pair == .ew) {
                    rangeUpper = rank
                } else {
                    ranges.append(CountedCardRange(pair: pair, suit: suit, ranks: rangeLower...rangeUpper, index: ranges.endIndex))
                    rangeLower = rank
                    rangeUpper = rank
                    pair = pair.opponents
                }
            }
            ranges.append(CountedCardRange(pair: pair, suit: suit, ranks: rangeLower...rangeUpper, index: ranges.endIndex))
            result[suit] = ranges
        }
        return result
    }
}
