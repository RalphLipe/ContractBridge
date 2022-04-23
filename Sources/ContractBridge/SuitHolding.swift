//
//  SuitHolding.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation

public struct PairRange {
    let pair: PairPosition
    let ranks: ClosedRange<Rank>
}

public typealias SuitLayoutIdentifier = Int

public struct SuitLayout {
    public let suit: Suit
    internal var rankPositions: [Position]
    
    public var id: SuitLayoutIdentifier {
        return (rankPositions.reversed().reduce(0) { return ($0 * 4) + $1.rawValue }) * 4 + suit.rawValue
    }
    
    public func clone() -> SuitLayout {
        return SuitLayout(suit: suit, rankPositions: rankPositions)
    }
    private init(suit: Suit, rankPositions: [Position]) {
        self.suit = suit
        self.rankPositions = rankPositions
        assert(rankPositions.count == Rank.allCases.count)
    }
    
    public init(suitLayoutId: SuitLayoutIdentifier) {
        var id = suitLayoutId
        suit = Suit(rawValue: id % 4)!
        rankPositions = []
        for _ in Rank.allCases {
            id /= 4     // Do this first to get rid of suit
            rankPositions.append(Position(rawValue: id % 4)!)
        }
    }
    
    internal mutating func setRanks(_ ranks: Set<Rank>, position: Position) {
        ranks.forEach { self[$0] = position }
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>, east: Set<Rank>, west: Set<Rank>) {
        assert(north.union(south).union(east).union(west).count == Rank.allCases.count)
        self.suit = suit
        self.rankPositions = Array(repeating: .north, count: Rank.allCases.count)
        setRanks(north, position: .north)
        setRanks(south, position: .south)
        setRanks(east, position: .east)
        setRanks(west, position: .west)
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>) {
        let allRemaining = Set(Rank.allCases).subtracting(north.union(south))
        self.init(suit: suit, north: north, south: south, east: allRemaining, west: [])
    }
    
    public func toDeal() -> Deal {
        var deal = Deal()
        for position in Position.allCases {
            deal[position] = Set(ranksFor(position: position).map { Card($0, suit) })
        }
        return deal
    }
    
    public subscript(rank: Rank) -> Position {
        get { return rankPositions[rank.rawValue] }
        set { rankPositions[rank.rawValue] = newValue }
    }
    
    public func ranksFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Set<Rank> {
        var ranks = Set<Rank>()
        _range.forEach { if self[$0] == position { ranks.insert($0) } }
        return ranks
    }
    
    public mutating func reassignRanks(pairs: Set<PairPosition> = [.ns, .ew], random: Bool) {
        for range in pairRanges() {
            if pairs.contains(range.pair) {
                let positions = range.pair.positions
                var count0 = ranksFor(position: positions.0, in: range.ranks).count
                var count1 = ranksFor(position: positions.1, in: range.ranks).count
                var ranks = range.ranks.map { $0 }
                assert(ranks.count == count0 + count1)
                if random { ranks.shuffle() }
                while count0 > 0 {
                    self[ranks.removeFirst()] = positions.0
                    count0 -= 1
                }
                while count1 > 0 {
                    self[ranks.removeFirst()] = positions.1
                    count1 -= 1
                }
                
            }
        }
    }
    
    public func pairRanges() -> [PairRange] {
        var ranges = Array<PairRange>()
        var rangeLower = Rank.two
        var rangeUpper = Rank.two
        var lastPair = self[.two].pairPosition
        for rank in Rank.three...Rank.ace {
            let thisPair = self[rank].pairPosition
            if thisPair == lastPair {
                rangeUpper = rank
            } else {
                ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
                rangeLower = rank
                rangeUpper = rank
                lastPair = thisPair
            }
        }
        ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
        return ranges
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
        hands.append(CompositeCardRange(allRanges: newRanges, pair: pair))    }
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
    public func playCards(from _trickSequence: TrickSequence) {
        for position in Position.allCases {
            if let ranks = _trickSequence.ranks[position] {
                let countedRange = self[position].solidRangeFor(ranks.lowerBound)
                let rank = countedRange.positionRanks.first
                countedRange.playCard(rank: rank, play: true)
            }
        }
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


//  IDEA:  deals are described by range, direction, and count:
//   Count of cards (4 bits)
//   Pair - 1 bit
//   Cards in "Primary" position (east/north) 4 bits

