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
    let children: [RankRange]
    let showsOutRange: RankRange?

    public var count: Int {
        return children.reduce(0) { $0 + $1.count }
    }
    
    public var isEmpty: Bool {
        for rankRange in children {
            if rankRange.count > 0 { return false }
        }
        return true
    }
    
    public var ranks: RankSet {
        return children.reduce(RankSet()) { $0.union($1.ranks) }
    }
    
    public var isLow: Bool { return range.lowerBound == .two }
    public var isWinner: Bool { return range.upperBound == .ace }
    
    init(allRanges: [RankRange], showsOutRange: RankRange? = nil, pair: Pair) {
        self.range = allRanges.first!.range!.lowerBound...allRanges.last!.range!.upperBound
        self.showsOutRange = showsOutRange
        self.children = allRanges.compactMap { return $0.pair == pair ? $0 : nil }
    }
    
    // NOTE: This function assumes that child ranges are sorted in order from lowest to highest
    // Caller MUST be sure that count > 0 or a runtime error will occur
    internal func lowest(cover: RankRange? = nil) -> RankRange {
        var low: RankRange? = nil
        for child in children {
            if !child.isEmpty {
                if cover == nil || child >= cover! { return child }
                if low == nil { low = child }
            }
        }
        if low != nil { return low! }
        if showsOutRange != nil { return showsOutRange! }
        fatalError()
    }
    
    // As with lowest() this method requires that the caller ensure that the composite range is not empty
    internal func highest() -> RankRange {
        var high: RankRange? = nil
        for child in children {
            if !child.isEmpty { high = child }
        }
        if high != nil { return high! }
        if showsOutRange != nil { return showsOutRange! }
        fatalError()
    }
    
    func toCards(suit: Suit) -> [Card] {
        var cards: [Card] = []
        for rank in ranks {
            cards.append(Card(rank, suit))
        }
        return cards
    }

    func rankRangeFor(rank: Rank?) -> RankRange {
        guard let rank = rank else { return showsOutRange! }
        for child in children {
            if child.range!.contains(rank) { return child }
        }
        fatalError()
    }
    func rankRangeFor(range: ClosedRange<Rank>?) -> RankRange {
        // TODO: Clean up showsOut stuff ---
        guard let range = range else { return showsOutRange! }
        for child in children {
            if child.range!.contains(range.lowerBound) && child.count > 0 { return child }
        }
        fatalError()
    }

}
