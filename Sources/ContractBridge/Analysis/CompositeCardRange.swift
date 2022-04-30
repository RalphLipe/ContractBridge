//
//  CompositeCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


public class CompositeCardRange {
    public let suit: Suit
    public let ranks: ClosedRange<Rank>
    public let pair: PairPosition
    let cardRanges: [CountedCardRange]

    public var count: Int {
        return cardRanges.reduce(0) { $0 + $1.count }
    }
    
    public var isLow: Bool { return ranks.lowerBound == .two }
    public var isWinner: Bool { return ranks.upperBound == .ace }
    
    init(allRanges: [CountedCardRange], pair: PairPosition) {
        self.suit = allRanges.first!.suit
        self.pair = pair
        self.ranks = allRanges.first!.rangeRanks.lowerBound...allRanges.last!.rangeRanks.upperBound
        self.cardRanges = allRanges.compactMap { return $0.pair == pair ? $0 : nil }
    }
    
    // NOTE: This function assumes that child ranges are sorted in order from lowest to highest
    // Caller MUST be sure that remainingCount > 0 or a runtime error will occur
    internal func lowest(cover: CountedCardRange? = nil) -> CountedCardRange {
        var low: CountedCardRange? = nil
        for child in cardRanges {
            if child.count > 0 {
                if cover == nil || child >= cover! { return child }
                if low == nil { low = child }
            }
        }
        return low!
    }
    
    func toCards() -> [Card] {
        var cards: [Card] = []
        for child in cardRanges {
            if let positionRanks = child.positionRanks {
                for rank in positionRanks {
                    cards.append(Card(rank, suit))
                }
            }
        }
        return cards
    }

    func countedRangeFor(_ rank: Rank) -> CountedCardRange {
        for child in self.cardRanges {
            if child.rangeRanks.contains(rank) { return child }
        }
        fatalError()
    }

}
