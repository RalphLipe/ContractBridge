//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


internal class CountedCardRange: Comparable, CustomStringConvertible {
    private let suitHolding: SuitHolding
////    public let index: Int
    public var suit: Suit { return suitHolding.suit }
    public var pair: PairPosition
    public let ranks: ClosedRange<Rank>
    public let position: Position?
    public var count: Int
    public var positionRanks: Set<Rank>
    private var playCardDestination: CountedCardRange?

    init(suitHolding: SuitHolding, pair: PairPosition, ranks: ClosedRange<Rank>, position: Position? = nil, playCardDestination: CountedCardRange? = nil, positionRanks: Set<Rank> = []) {
        self.suitHolding = suitHolding
        self.pair = pair
    ////    self.index = index
        self.ranks = ranks
        self.count = positionRanks.count    // TODO: Is this right?  Can we clone without ranks?
        self.position = position
        assert(position == nil || position?.pairPosition == pair)
        self.positionRanks = positionRanks
        self.playCardDestination = playCardDestination
    }
    
//    func copy() -> CountedCardRange {
//        return CountedCardRange(suitHolding: suitHolding, pair: pair, ranks: ranks)
//    }
    
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
    
    public func playCard(rank: Rank? = nil, play: Bool) {
        guard let playTo = playCardDestination else { fatalError("Can not play card from this range") }
        let takeFrom = play ? self : playTo
        let moveTo = play ? playTo : self
        takeFrom.count -= 1
        moveTo.count += 1
        if count < 0 || playTo.count < 0 { fatalError("Card count has gone negative") }
        if let rank = rank {
            assert(ranks.contains(rank))
            assert(takeFrom.positionRanks.contains(rank))
            assert(moveTo.positionRanks.contains(rank) == false)
            takeFrom.positionRanks.remove(rank)
            moveTo.positionRanks.insert(rank)
        }
    }
}
