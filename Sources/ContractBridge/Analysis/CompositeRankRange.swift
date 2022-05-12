//
//  CompositeRankRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


public class CompositeRankRange: Comparable {
    public static func < (lhs: CompositeRankRange, rhs: CompositeRankRange) -> Bool {
        return lhs.range.upperBound < rhs.range.lowerBound
    }
    
    public static func == (lhs: CompositeRankRange, rhs: CompositeRankRange) -> Bool {
        return lhs.range.lowerBound == rhs.range.lowerBound && lhs.range.upperBound == rhs.range.upperBound
    }
    
    public let range: ClosedRange<Rank>
    public let pair: PairPosition
    let cardRanges: [RankRange]

    public var count: Int {
        return cardRanges.reduce(0) { $0 + $1.count }
    }
    
    public var ranks: Set<Rank> {
        return cardRanges.reduce(Set<Rank>()) { $0.union($1.ranks) }
    }
    
    public var isLow: Bool { return range.lowerBound == .two }
    public var isWinner: Bool { return range.upperBound == .ace }
    
    init(allRanges: [RankRange], pair: PairPosition) {
        self.pair = pair
        self.range = allRanges.first!.range.lowerBound...allRanges.last!.range.upperBound
        self.cardRanges = allRanges.compactMap { return $0.pair == pair ? $0 : nil }
    }
    
    // NOTE: This function assumes that child ranges are sorted in order from lowest to highest
    // Caller MUST be sure that remainingCount > 0 or a runtime error will occur
    internal func lowest(cover: RankRange? = nil) -> RankRange {
        var low: RankRange? = nil
        for child in cardRanges {
            if child.count > 0 {
                if cover == nil || child >= cover! { return child }
                if low == nil { low = child }
            }
        }
        return low!
    }
    
    func toCards(suit: Suit) -> [Card] {
        var cards: [Card] = []
        for rank in ranks {
            cards.append(Card(rank, suit))
        }
        return cards
    }

    func rankRangeFor(rank: Rank) -> RankRange {
        for child in self.cardRanges {
            if child.range.contains(rank) { return child }
        }
        fatalError()
    }
    func rankRangeFor(range: ClosedRange<Rank>) -> RankRange {
        for child in self.cardRanges {
            if child.range.contains(range.lowerBound) && child.count > 0 { return child }
        }
        fatalError()
    }

}
