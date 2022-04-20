//
//  SuitHolding.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation


public class SuitHolding {
    public let suit: Suit
    private var playedRanges: [CountedCardRange]
    private var hands: [CompositeCardRange]
    private var handRanges: [[CountedCardRange]]
    
    public init(deal: Deal, suit: Suit) {
        self.suit = suit
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        // Now that "self" has all members intialized, really finish initializing
        createPlayedRanges(from: deal)
        // The createHand method will copy all of the ranges from the playedRanges
        for position in Position.allCases {
            createHand(for: position, from: deal)
        }
    }
    
    private func createHand(for _position: Position, from _deal: Deal) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pairPosition
        let positionCards = _deal[_position].filter { $0.suit == suit }
        let positionRanks = Set(positionCards.map { $0.rank} )
        var newRanges: [CountedCardRange] = []
        for playRange in playedRanges {
            if playRange.pair == pair {
                let rangeRanks = Set(playRange.ranks).intersection(positionRanks)
                newRanges.append(CountedCardRange(suitHolding: self, pair: pair, ranks: playRange.ranks, position: _position, playCardDestination: playRange, positionRanks: rangeRanks))
            } else {
                newRanges.append(playRange)
            }
        }
        handRanges.append(newRanges)
        hands.append(CompositeCardRange(allRanges: newRanges, pair: pair))
    }
    
    internal subscript(position: Position) -> CompositeCardRange {
        get { return hands[position.rawValue] }
    }
    
    private func createPlayedRanges(from _deal: Deal) {
        let nsAllCards = _deal[.north] + _deal[.south]
        let ranks = Set(nsAllCards.filter(by: suit).map { $0.rank })
        assert(playedRanges.count == 0)
        var rangeLower = Rank.two
        var rangeUpper = Rank.two
        var pair: PairPosition = ranks.contains(.two) ? .ns : .ew
        for rank in Rank.three...Rank.ace {
            let isNsCard = ranks.contains(rank)
            if (isNsCard && pair == .ns) || (isNsCard == false && pair == .ew) {
                rangeUpper = rank
            } else {
                playedRanges.append(CountedCardRange(suitHolding: self, pair: pair, ranks: rangeLower...rangeUpper))
                rangeLower = rank
                rangeUpper = rank
                pair = pair.opponents
            }
        }
        playedRanges.append(CountedCardRange(suitHolding: self, pair: pair, ranks: rangeLower...rangeUpper))
    }
    
//    internal func playCard(_ cardRange: CountedCardRange?, rank: Rank? = nil) {
 //       if let cardRange = cardRange {
 //           cardRange.count -= 1
 //       }
 //   }
    
    func choices(_ position: Position) -> RangeChoices {
        var group: [CountedCardRange] = []
        var groupHasCards = false
        var allRanges: [CompositeCardRange] = []
        for range in handRanges[position.rawValue] {
            if range.position == position || range.count == range.ranks.count {
                group.append(range)
                groupHasCards = groupHasCards || (range.position == position && range.count > 0)
            } else {
                if groupHasCards { allRanges.append(CompositeCardRange(allRanges: group, pair: position.pairPosition))}
                group = []
                groupHasCards = false
            }
        }
        if groupHasCards { allRanges.append(CompositeCardRange(allRanges: group, pair: position.pairPosition))}
        return RangeChoices(allRanges, position: position)
    }
    
}

struct RangeChoices {
    let position: Position
    let all: [CompositeCardRange]
    let win: CompositeCardRange?
    let mid: [CompositeCardRange]?
    let low: CompositeCardRange?
    
    init(_ all: [CompositeCardRange], position: Position) {
        self.position = position
        self.all = all
        var r = all
        self.low = r.count > 0 && r.first!.ranks.lowerBound == .two ? r.removeFirst() : nil
        self.win = r.count > 0 && r.last!.ranks.upperBound == .ace ? r.removeLast() : nil
        self.mid = r.count > 0 ? r : nil
    }
}
