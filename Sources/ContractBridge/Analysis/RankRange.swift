//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


internal class RankRange: Comparable {
    private let suitHolding: SuitHolding
    public let index: Int
    public var pair: Pair?
    public let position: Position?
    public let range: ClosedRange<Rank>
    public var count: Int { return ranks.count }
    public var ranks: Set<Rank>
    private var playCardDestination: RankRange?

    init(suitHolding: SuitHolding, index: Int, pair: Pair?, range: ClosedRange<Rank>, position: Position? = nil, playCardDestination: RankRange? = nil, ranks: Set<Rank> = []) {
        self.suitHolding = suitHolding
        self.index = index
        self.pair = pair
        self.range = range
        self.position = position
        assert(position == nil || position?.pair == pair)
        self.ranks = ranks
        self.playCardDestination = playCardDestination
    }
    
    init(from: RankRange, suitHolding: SuitHolding, playCardDestination: RankRange? = nil) {
        self.suitHolding = suitHolding
        self.index = from.index
        self.pair = from.pair
        self.range = from.range
        self.position = from.position
        self.playCardDestination = playCardDestination
        self.ranks = from.ranks
    }

    public static func < (lhs: RankRange, rhs: RankRange) -> Bool {
        return lhs.range.upperBound < rhs.range.lowerBound
    }
    
    public static func == (lhs: RankRange, rhs: RankRange) -> Bool {
        return lhs.range == rhs.range
    }
    
    
    public var promotedRange: ClosedRange<Rank> {
        if let position = position {
            return suitHolding.promotedRangeFor(position: position, index: index)
        }
        return range
    }
    
    public func play(rank: Rank? = nil) -> Rank {
        guard let playTo = playCardDestination else { fatalError("Can not play card from this range") }
       // assert((rank == nil) == false || play == true)
        let playRank = rank == nil ? self.ranks.min() : rank
        guard let playRank = playRank else {
            fatalError("Play called on range with no ranks")
        }
        assert(playTo.ranks.contains(playRank) == false)
        self.ranks.remove(playRank)
        playTo.ranks.insert(playRank)
        return playRank
    }
    
    public func undoPlay(rank: Rank) -> Void {
        guard let removeFrom = playCardDestination else { fatalError("Can not undo play from this range") }
        assert(removeFrom.ranks.contains(rank))
        assert(self.ranks.contains(rank) == false)
        removeFrom.ranks.remove(rank)
        self.ranks.insert(rank)
    }
}

// RankRanges are simply shown as the range they represent
// TODO: Is this appropriate to be internal?
internal extension String.StringInterpolation {
    mutating func appendInterpolation(_ rankRange: RankRange, style: ContractBridge.Style = .symbol) {
        appendLiteral("\(rankRange.range, style: style)")
        }
}

// TODO:  Is this in the right place?
public extension String.StringInterpolation {
    mutating func appendInterpolation(_ ranks: ClosedRange<Rank>, style: ContractBridge.Style = .symbol) {
        appendLiteral(ranks.lowerBound == ranks.upperBound ? "\(ranks.lowerBound, style: style)" : "\(ranks.lowerBound, style: style)...\(ranks.upperBound, style: style)")
        }
}
