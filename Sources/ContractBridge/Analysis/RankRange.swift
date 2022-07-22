//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



internal class RankRange: Comparable {
    private let suitHolding: SuitHolding
    public let xxindex: Int
    public var pair: Pair?
    public let position: Position?
    public let range: ClosedRange<Rank>?
    public var count: Int { return ranks.count }
    public var isEmpty: Bool { return ranks.isEmpty }
    public var ranks: RankSet
    private var playCardDestination: RankRange?

    init(suitHolding: SuitHolding, index: Int, pair: Pair?, range: ClosedRange<Rank>, position: Position? = nil, playCardDestination: RankRange? = nil, ranks: RankSet = RankSet()) {
        self.suitHolding = suitHolding
        self.xxindex = index
        self.pair = pair
        self.range = range
        self.position = position
        assert(position == nil || position?.pair == pair)
        self.ranks = ranks
        self.playCardDestination = playCardDestination
    }
    
    // This initialializer is only used to create the "showOutRange" special case that returns nil for played cards
    init(suitHolding: SuitHolding, position: Position) {
        self.suitHolding = suitHolding
        self.xxindex = -1     // Set to invalid index
        self.pair = position.pair
        self.position = position
        self.range = nil
        self.ranks = RankSet()
        self.playCardDestination = nil
    }
    
    init(from: RankRange, suitHolding: SuitHolding, playCardDestination: RankRange? = nil) {
        self.suitHolding = suitHolding
        self.xxindex = from.xxindex
        self.pair = from.pair
        self.range = from.range
        self.position = from.position
        self.playCardDestination = playCardDestination
        self.ranks = from.ranks
    }

    public static func < (lhs: RankRange, rhs: RankRange) -> Bool {
        if lhs.range == nil && rhs.range == nil { return false }
        guard let lhsRange = lhs.range else { return true }
        guard let rhsRange = rhs.range else { return false }
        return lhsRange.upperBound < rhsRange.lowerBound
    }
    
    public static func == (lhs: RankRange, rhs: RankRange) -> Bool {
        return lhs.range == rhs.range
    }

    
    public var promotedRange: ClosedRange<Rank>? {
        guard let range = range else { return nil }
        guard let position = position else { return range }
        // TODO: This is the only place where "index" is used?  Can I get rid of it...?
        return suitHolding.promotedRangeFor(position: position, index: xxindex)
    }
    
    public func play(rank: Rank? = nil) -> Rank? {
        if range == nil {
            if rank != nil { fatalError("Can't specify a rank when playing to shows-out range") }
            suitHolding.playShowsOut(position: position!)
            return nil
        }
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
    
    public func undoPlay(rank: Rank?) -> Void {
        guard let rank = rank else {
            // TODO: Error checking here.
            suitHolding.undoPlayShowsOut(position: position!)
            return
        }
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
        if let range = rankRange.range {
            appendLiteral("\(range, style: style)")
        } else {
            appendLiteral("shows out")
        }
    }
}

// TODO:  Is this in the right place?
public extension String.StringInterpolation {
    mutating func appendInterpolation(_ ranks: ClosedRange<Rank>, style: ContractBridge.Style = .symbol) {
        appendLiteral(ranks.lowerBound == ranks.upperBound ? "\(ranks.lowerBound, style: style)" : "\(ranks.lowerBound, style: style)...\(ranks.upperBound, style: style)")
    }
}

