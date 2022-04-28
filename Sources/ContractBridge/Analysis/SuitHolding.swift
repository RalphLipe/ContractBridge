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
        self.low = r.count > 0 && r.first!.isLow ? r.removeFirst() : nil
        self.win = r.count > 0 && r.last!.isWinner ? r.removeLast() : nil
        self.mid = r.count > 0 ? r : nil
    }
}

public class SuitHolding {
    public var suit: Suit { initialLayout.suit }
    public let initialLayout: SuitLayout
    public let hasPositionRanks: Bool
    private var playedRanges: [CountedCardRange]
    private var hands: [CompositeCardRange]
    private var handRanges: [[CountedCardRange]]
    private var fixedPairRanges: [Set<ClosedRange<Rank>>]
 

    

    public init(suitLayout: SuitLayout) {
        self.initialLayout = suitLayout
        self.hasPositionRanks = true
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        self.fixedPairRanges = Array<Set<ClosedRange<Rank>>>(repeating: [], count: PairPosition.allCases.count)
        // Now that "self" has all members intialized, really finish initializing
        // The createHand method will copy all of the ranges from the playedRanges
        let pairRanges = initialLayout.pairRanges()
        for i in pairRanges.indices {
            let pairRange = pairRanges[i]
            playedRanges.append(CountedCardRange(suitHolding: self, index: i, pair: pairRange.pair, ranks: pairRange.ranks))
        }
       Position.allCases.forEach { createHand(for: $0) }
    }
    
    internal init(from: SuitHolding, copyPositionRanks: Bool) {
        self.initialLayout = from.initialLayout
        self.hasPositionRanks = copyPositionRanks
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        self.fixedPairRanges = from.fixedPairRanges
        
        self.playedRanges = from.playedRanges.map { CountedCardRange(from: $0, suitHolding: self, copyPositionRanks: copyPositionRanks)}
        Position.allCases.forEach { copyHand(from: from, for: $0, copyPositionRanks: copyPositionRanks)}
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
    
    private func copyHand(from: SuitHolding, for _position: Position, copyPositionRanks: Bool) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pairPosition
        var newRanges: [CountedCardRange] = []
        for i in playedRanges.indices {
            if playedRanges[i].pair == pair {
                newRanges.append(CountedCardRange(from: from.handRanges[_position.rawValue][i], suitHolding: self, copyPositionRanks: copyPositionRanks, playCardDestination: playedRanges[i]))
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
    
    // This is called from client code to change the holding in a permanant, non-reveresable way.  Update fixedE/W
    // ranges if:
    //      Winner is N/S then all remaining high E/W cards about winner must be in 2nd hand
    //      Winner is 4th hand then any range from 3nd hand through played by 4th hand are known.  If finesse of 10 in AQK wins
    //      with king in 4th seat then 2nd seat must have the jack.
    //  These cards will not be moved from their existing ranges when considering odds since their placement is known in the
    //  current configuration
    public func playCards(from _trick: Trick) {
        assert(_trick.isComplete)
        for position in Position.allCases {
            if let played = _trick.cards[position] {
                if played.suit == suit {
                    let range = self[position].countedRangeFor(played.rank)
                    range.playCard(rank: played.rank, play: true)
                }
            }
        }
        if _trick.winningCard.suit == suit {
            updateKnownHoldings(winningRank: _trick.winningCard.rank, winningPosition: _trick.winningPosition)
        }
    }
    
    // TODO: Still need to update double finesse when 4th hand plays high rank but for now just north/south winning
    // TODO:  This should work for either pair having know cards. Right now just E/W
    private func updateKnownHoldings(winningRank: Rank, winningPosition: Position) {
        if winningPosition.pairPosition == .ns {
            for range in playedRanges {
                if range.pair == .ew && range.ranks.lowerBound > winningRank {
                    fixedPairRanges[PairPosition.ew.rawValue].insert(range.ranks)
                }
            }
        }
    }
    
    public func playCards(from _leadStats: LeadStatistics) {
        var winningRank: Rank? = nil
        let winningPosition = _leadStats.trickSequence.winningPosition
        for position in Position.allCases {
            if let played = _leadStats.trickSequence.play[position] {
                let range = self[position].countedRangeFor(played.lowerBound)
                let rank = range.positionRanks!.first   // TODO: Think this through more...
                range.playCard(rank: rank, play: true)
                if position == winningPosition { winningRank = rank }
            }
        }
        updateKnownHoldings(winningRank: winningRank!, winningPosition: winningPosition)
    }
    


    
    // NOTE:  Indices (saveIndex) is index into composite card range, NOT handRanges
    private func saveAndShiftHoldings(pairPosition: PairPosition, saveIndex: Int, body: (_ combinations: Int) -> Void) -> Void {
        let positions = pairPosition.positions
        assert(self[positions.0].cardRanges.endIndex == self[positions.1].cardRanges.endIndex)
        if saveIndex < self[positions.0].cardRanges.endIndex {
            let range0 = self[positions.0].cardRanges[saveIndex]
            // TODO:  IMPORTANT!
            if self.fixedPairRanges[pairPosition.rawValue].contains(range0.ranks) {
                saveAndShiftHoldings(pairPosition: pairPosition, saveIndex: saveIndex + 1, body: body)
            } else {
                let range1 = self[positions.1].cardRanges[saveIndex]
                let count0 = range0.count
                let count1 = range1.count
                range0.count += count1
                range1.count = 0
                saveAndShiftHoldings(pairPosition: pairPosition, saveIndex: saveIndex + 1, body: body)
                range0.count = count0
                range1.count = count1
            }
        } else {
            forAllCombinations(pairPosition: pairPosition, moveIndex: 0, combinations: 1, body: body)
        }
    }
    
    private func factorial(_ n: Int) -> Int {
        assert(n > 0)
        return n == 1 ? 1 : n * factorial(n - 1)
    }
    
    private func combinations(numberOfCards: Int, numberOfSlots: Int) -> Int {
        if numberOfCards == 0 || numberOfSlots == 0 || numberOfCards == numberOfSlots {
            return 1
        }
        assert(numberOfCards > numberOfSlots)
        return factorial(numberOfCards) / (factorial(numberOfSlots) * factorial(numberOfCards - numberOfSlots))
    }
    
    
    
    // NOTE:  Indices (moveIndex) is index into composite card range, NOT handRanges
    private func forAllCombinations(pairPosition: PairPosition, moveIndex: Int, combinations: Int, body: (_ combinations: Int) -> Void) -> Void {
        let positions = pairPosition.positions
        if moveIndex < self[positions.0].cardRanges.endIndex {
            forAllCombinations(pairPosition: pairPosition, moveIndex: moveIndex + 1, combinations: combinations, body: body)
            let range0 = self[positions.0].cardRanges[moveIndex]
            // If the cards are "fixed" then we don't move them.  Their position is know based on previous play
            if self.fixedPairRanges[pairPosition.rawValue].contains(range0.ranks) == false {
                let range1 = self[positions.1].cardRanges[moveIndex]
                let numberOfCards = range0.count
                while range0.count > 0 {
                    range0.count -= 1
                    range1.count += 1
                    // You could compute this using either range for numberOfSlots...
                    let newCombinations = combinations * self.combinations(numberOfCards: numberOfCards, numberOfSlots: range0.count)
                    forAllCombinations(pairPosition: pairPosition, moveIndex: moveIndex + 1, combinations: newCombinations, body: body)
                }
                range0.count = numberOfCards
                range1.count = 0
            }
        } else {
            body(combinations)
        }
        
    }
    
    public func forAllCombinations(pairPosition: PairPosition, _ body: (_ combinations: Int) -> Void) -> Void {
        saveAndShiftHoldings(pairPosition: pairPosition, saveIndex: 0, body: body)
    }
    
    


    // Returns true if there are no played cards and the hands contain 13 cards
    public var isFullHolding: Bool {
        return (Position.allCases.reduce(0) { $0 + self[$1].count }) == Rank.allCases.count
    }
}


