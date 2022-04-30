//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


internal class CountedCardRange: Comparable, CustomStringConvertible {
    private let suitHolding: SuitHolding
    public let index: Int
    public var suit: Suit { return suitHolding.suit }
    public var pair: PairPosition
    public let rangeRanks: ClosedRange<Rank>
    public let position: Position?
    public var count: Int
    public var positionRanks: Set<Rank>?
    private var playCardDestination: CountedCardRange?

    init(suitHolding: SuitHolding, index: Int, pair: PairPosition, rangeRanks: ClosedRange<Rank>, position: Position? = nil, playCardDestination: CountedCardRange? = nil, positionRanks: Set<Rank>? = []) {
        self.suitHolding = suitHolding
        self.index = index
        self.pair = pair
        self.rangeRanks = rangeRanks
        if let positionRanks = positionRanks {
            self.count = positionRanks.count
        } else {
            self.count = 0
        }
        self.position = position
        assert(position == nil || position?.pairPosition == pair)
        self.positionRanks = positionRanks
        self.playCardDestination = playCardDestination
    }
    
    init(from: CountedCardRange, suitHolding: SuitHolding, copyPositionRanks: Bool, playCardDestination: CountedCardRange? = nil) {
        self.suitHolding = suitHolding
        self.index = from.index
        self.pair = from.pair
        self.rangeRanks = from.rangeRanks
        self.count = from.count
        self.position = from.position
        self.playCardDestination = playCardDestination
        self.positionRanks = copyPositionRanks ? from.positionRanks : nil
  ///      assert(copyPositionRanks == false || positionRanks.count == self.count)
    }

    public static func < (lhs: CountedCardRange, rhs: CountedCardRange) -> Bool {
        return lhs.rangeRanks.upperBound < rhs.rangeRanks.lowerBound
    }
    
    public static func == (lhs: CountedCardRange, rhs: CountedCardRange) -> Bool {
        return lhs.rangeRanks == rhs.rangeRanks
    }
    
    public var description: String {
        if rangeRanks.lowerBound == rangeRanks.upperBound { return rangeRanks.lowerBound.shortDescription }
        return "\(rangeRanks.lowerBound.shortDescription)...\(rangeRanks.upperBound.shortDescription)"
    }
    
    public var promotedRange: ClosedRange<Rank> {
        if let position = position {
            return suitHolding.promotedRangeFor(position: position, index: index)
        }
        return rangeRanks
    }
    
    public func playCard(rank: Rank? = nil, play: Bool) {
        guard let playTo = playCardDestination else { fatalError("Can not play card from this range") }
        let takeFrom = play ? self : playTo
        let moveTo = play ? playTo : self
        takeFrom.count -= 1
        moveTo.count += 1
        if count < 0 || playTo.count < 0 { fatalError("Card count has gone negative") }
        assert((rank == nil && takeFrom.positionRanks == nil && moveTo.positionRanks == nil) || (rank != nil && takeFrom.positionRanks != nil && moveTo.positionRanks != nil))
        if let rank = rank {
            assert(rangeRanks.contains(rank))
            assert(takeFrom.positionRanks!.contains(rank))
            assert(moveTo.positionRanks!.contains(rank) == false)
            takeFrom.positionRanks!.remove(rank)
            moveTo.positionRanks!.insert(rank)
        }
    }
}
