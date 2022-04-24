//
//  SuitHolding.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation



public struct RangeChoices {
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

public class SuitHolding {
    public var suit: Suit { initialLayout.suit }
    public let initialLayout: SuitLayout
    private var playedRanges: [CountedCardRange]
    private var hands: [CompositeCardRange]
    private var handRanges: [[CountedCardRange]]
 

    

    public init(suitLayout: SuitLayout) {
        self.initialLayout = suitLayout
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        // Now that "self" has all members intialized, really finish initializing
        // The createHand method will copy all of the ranges from the playedRanges
        let pairRanges = initialLayout.pairRanges()
        for i in pairRanges.indices {
            let pairRange = pairRanges[i]
            playedRanges.append(CountedCardRange(suitHolding: self, index: i, pair: pairRange.pair, ranks: pairRange.ranks))
        }
       Position.allCases.forEach { createHand(for: $0) }
    }
    
    internal init(from: SuitHolding, usePositionRanks: Bool) {
        self.initialLayout = from.initialLayout
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        
        self.playedRanges = from.playedRanges.map { CountedCardRange(from: $0, suitHolding: self, usePositionRanks: usePositionRanks)}
        Position.allCases.forEach { copyHand(from: from, for: $0, usePositionRanks: usePositionRanks)}
    }
    
    private func createHand(for _position: Position) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pairPosition
        var newRanges: [CountedCardRange] = []
        for playRange in playedRanges {
            if playRange.pair == pair {
                let positionRanks = initialLayout.ranksFor(position: _position, in: playRange.ranks)
                newRanges.append(CountedCardRange(suitHolding: self, index: playRange.index, pair: pair, ranks: playRange.ranks, position: _position, playCardDestination: playRange, positionRanks: positionRanks))
            } else {
                newRanges.append(playRange)
            }
        }
        handRanges.append(newRanges)
        hands.append(CompositeCardRange(allRanges: newRanges, pair: pair))
    }
    
    private func copyHand(from: SuitHolding, for _position: Position, usePositionRanks: Bool) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pairPosition
        var newRanges: [CountedCardRange] = []
        for i in playedRanges.indices {
            if playedRanges[i].pair == pair {
                newRanges.append(CountedCardRange(from: from.handRanges[_position.rawValue][i], suitHolding: self, usePositionRanks: usePositionRanks, playCardDestination: playedRanges[i]))
            } else {
                newRanges.append(playedRanges[i])
            }
        }
        handRanges.append(newRanges)
        hands.append(CompositeCardRange(allRanges: newRanges, pair: pair))
    }
    
    public subscript(position: Position) -> CompositeCardRange {
        get { return hands[position.rawValue] }
    }
    
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
  
  
    internal func promotedRangeFor(position: Position, index: Int) -> ClosedRange<Rank> {
        let startRange = handRanges[position.rawValue][index].ranks
        var upperBound = startRange.upperBound
        var i = index + 1
        while i < handRanges[position.rawValue].endIndex {
            let range = handRanges[position.rawValue][i]
            if range.position == position || range.count == range.ranks.count {
                upperBound = range.ranks.upperBound
                i += 1
            } else {
                break
            }
        }
        return startRange.lowerBound...upperBound
    }
    
    public func playCards(from _trick: Trick) {
        assert(_trick.isComplete)
        for position in Position.allCases {
            if let played = _trick.cards[position] {
                if played.suit == suit {
                    let range = self[position].solidRangeFor(played.rank)
                    range.playCard(rank: played.rank, play: true)
                }
            }
        }
    }
    
    public func movePairCardsTo(_ position: Position) {
        for i in playedRanges.indices {
            if handRanges[position.rawValue][i].position == position {
                handRanges[position.rawValue][i].count += handRanges[position.partner.rawValue][i].count
                handRanges[position.partner.rawValue][i].count = 0
                handRanges[position.rawValue][i].positionRanks.formUnion(handRanges[position.partner.rawValue][i].positionRanks)
                handRanges[position.partner.rawValue][i].positionRanks = []
            }
        }
    }

    // TODO:  This is only used by test code.  Move to test???
    public func playCards(from _play: [Position:ClosedRange<Rank>]) {
        for position in Position.allCases {
            if let ranks = _play[position] {
                let countedRange = self[position].solidRangeFor(ranks.lowerBound)
                let rank = countedRange.positionRanks.first
                assert(rank != nil)
                countedRange.playCard(rank: rank, play: true)
            }
        }
    }

    // Returns true if there are no played cards and the hands contain 13 cards
    public var isFullHolding: Bool {
        return (Position.allCases.reduce(0) { $0 + self[$1].count }) == Rank.allCases.count
    }
}


