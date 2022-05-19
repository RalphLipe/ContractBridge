//
//  SuitHolding.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation

public struct RangeChoices {
    public let position: Position
    public let all: [CompositeRankRange]
    public let win: CompositeRankRange?
    public let mid: [CompositeRankRange]?
    public let low: CompositeRankRange?
    
    init(_ all: [CompositeRankRange], position: Position) {
        self.position = position
        self.all = all
        var r = all
        // It is important to look at the ranges in this order: Win, Low and then the rest
        // because when the final range is 2...A the last AND first are both winners and low
        self.win = r.count > 0 && r.last!.isWinner ? r.removeLast() : nil
        self.low = r.count > 0 && r.first!.isLow ? r.removeFirst() : nil
        self.mid = r.count > 0 ? r : nil
    }
}

public class SuitHolding {
    public let initialLayout: SuitLayout
    private var playedRanges: [RankRange]
    private var hands: [CompositeRankRange]
    private var handRanges: [[RankRange]]
    private var fixedPairRanges: [Set<ClosedRange<Rank>>]
 

    


    public init(suitLayout: SuitLayout) {
        self.initialLayout = suitLayout
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        self.fixedPairRanges = Array<Set<ClosedRange<Rank>>>(repeating: [], count: Pair.allCases.count)
        // Now that "self" has all members intialized, really finish initializing
        // The createHand method will copy all of the ranges from the playedRanges
        let pairRanges = initialLayout.pairRanges()
        for i in pairRanges.indices {
            let pairRange = pairRanges[i]
            playedRanges.append(RankRange(suitHolding: self, index: i, pair: pairRange.pair, range: pairRange.range))
            if pairRange.pair == nil {
                // If no pair owns these cards then treat them as "played" by nobody.
                pairRange.range.forEach { playedRanges.last!.ranks.insert($0) }
            }
        }
       Position.allCases.forEach { createHand(for: $0) }
    }
    
    internal init(from: SuitHolding) {
        self.initialLayout = from.initialLayout
        self.playedRanges = []
        self.hands = []
        self.handRanges = []
        self.fixedPairRanges = from.fixedPairRanges
        
        self.playedRanges = from.playedRanges.map { RankRange(from: $0, suitHolding: self) }
        Position.allCases.forEach { copyHand(from: from, for: $0) }
    }
    
    private func createHand(for _position: Position) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pair
        var newRanges: [RankRange] = []
        for playedRange in playedRanges {
            if playedRange.pair == pair {
                let positionRanks = initialLayout.ranksFor(position: _position, in: playedRange.range)
                newRanges.append(RankRange(suitHolding: self, index: playedRange.index, pair: pair, range: playedRange.range, position: _position, playCardDestination: playedRange, ranks: positionRanks))
            } else {
                newRanges.append(playedRange)
            }
        }
        handRanges.append(newRanges)
        hands.append(CompositeRankRange(allRanges: newRanges, pair: pair))
    }
    
    private func copyHand(from: SuitHolding, for _position: Position) {
        assert(_position.rawValue == hands.count)
        let pair = _position.pair
        var newRanges: [RankRange] = []
        for i in playedRanges.indices {
            if playedRanges[i].pair == pair {
                newRanges.append(RankRange(from: from.handRanges[_position.rawValue][i], suitHolding: self, playCardDestination: playedRanges[i]))
            } else {
                newRanges.append(playedRanges[i])
            }
        }
        handRanges.append(newRanges)
        hands.append(CompositeRankRange(allRanges: newRanges, pair: pair))
    }
    
    public subscript(position: Position) -> CompositeRankRange {
        get { return hands[position.rawValue] }
    }
    
    public func choices(_ position: Position) -> RangeChoices {
        var group: [RankRange] = []
        var groupHasCards = false
        var allRanges: [CompositeRankRange] = []
        for rankRange in handRanges[position.rawValue] {
            if rankRange.position == position || rankRange.count == rankRange.range.count {
                group.append(rankRange)
                groupHasCards = groupHasCards || (rankRange.position == position && rankRange.count > 0)
            } else {
                if groupHasCards { allRanges.append(CompositeRankRange(allRanges: group, pair: position.pair))}
                group = []
                groupHasCards = false
            }
        }
        if groupHasCards { allRanges.append(CompositeRankRange(allRanges: group, pair: position.pair))}
        return RangeChoices(allRanges, position: position)
    }
  
  
    internal func promotedRangeFor(position: Position, index: Int) -> ClosedRange<Rank> {
        let startRange = handRanges[position.rawValue][index].range
        var upperBound = startRange.upperBound
        var i = index + 1
        while i < handRanges[position.rawValue].endIndex {
            let range = handRanges[position.rawValue][i]
            if range.position == position || range.count == range.range.count {
                upperBound = range.range.upperBound
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
    public func playCards(from _trick: Trick, suit: Suit) {
        assert(_trick.isComplete)
        for position in Position.allCases {
            if let played = _trick.cards[position] {
                if played.suit == suit {
                    let range = self[position].rankRangeFor(rank: played.rank)
                    _ = range.play(rank: played.rank)
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
        if winningPosition.pair == .ns {
            for range in playedRanges {
                if range.pair == .ew && range.range.lowerBound > winningRank {
                    fixedPairRanges[Pair.ew.rawValue].insert(range.range)
                }
            }
        }
    }
    
    public func playCards(from _leadStats: LeadStatistics) -> [Position: Rank] {
        var ranksPlayed: [Position:Rank] = [:]
        for position in Position.allCases {
            if let played = _leadStats.trickSequence.play[position] {
                let range = self[position].rankRangeFor(range: played)
                ranksPlayed[position] = range.play()
            }
        }
        let winningPosition = _leadStats.trickSequence.winningPosition
        updateKnownHoldings(winningRank: ranksPlayed[winningPosition]!, winningPosition: winningPosition)
        return ranksPlayed
    }
    


    
    // NOTE:  Indices (saveIndex) is index into composite card range, NOT handRanges
    private func saveAndShiftHoldings(pair: Pair, saveIndex: Int, body: (_ combinations: Int) -> Void) -> Void {
        let positions = pair.positions
        assert(self[positions.0].children.endIndex == self[positions.1].children.endIndex)
        if saveIndex < self[positions.0].children.endIndex {
            let range0 = self[positions.0].children[saveIndex]
            // TODO:  IMPORTANT!
            if self.fixedPairRanges[pair.rawValue].contains(range0.range) {
                saveAndShiftHoldings(pair: pair, saveIndex: saveIndex + 1, body: body)
            } else {
                let range1 = self[positions.1].children[saveIndex]
                let ranks0 = range0.ranks
                let ranks1 = range1.ranks
                range0.ranks.formUnion(ranks1)
                range1.ranks = []
                saveAndShiftHoldings(pair: pair, saveIndex: saveIndex + 1, body: body)
                range0.ranks = ranks0
                range1.ranks = ranks1
            }
        } else {
            forAllCombinations(pair: pair, moveIndex: 0, combinations: 1, body: body)
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
    private func forAllCombinations(pair: Pair, moveIndex: Int, combinations: Int, body: (_ combinations: Int) -> Void) -> Void {
        let positions = pair.positions
        if moveIndex < self[positions.0].children.endIndex {
            forAllCombinations(pair: pair, moveIndex: moveIndex + 1, combinations: combinations, body: body)
            let range0 = self[positions.0].children[moveIndex]
            // If the cards are "fixed" then we don't move them.  Their position is know based on previous play
            if self.fixedPairRanges[pair.rawValue].contains(range0.range) == false {
                let range1 = self[positions.1].children[moveIndex]
                let numberOfCards = range0.count
                let originalRanks = range0.ranks
                while range0.count > 0 {
                    range1.ranks.insert(range0.ranks.remove(range0.ranks.min()!)!)
                    // You could compute this using either range for numberOfSlots...
                    let newCombinations = combinations * self.combinations(numberOfCards: numberOfCards, numberOfSlots: range0.count)
                    forAllCombinations(pair: pair, moveIndex: moveIndex + 1, combinations: newCombinations, body: body)
                }
                range0.ranks = originalRanks
                range1.ranks = []
            }
        } else {
            body(combinations)
        }
        
    }
    
    public func forAllCombinations(pair: Pair, _ body: (_ combinations: Int) -> Void) -> Void {
        saveAndShiftHoldings(pair: pair, saveIndex: 0, body: body)
    }
    
    


    // Returns true if there are no played cards and the hands contain 13 cards
    public var isFullHolding: Bool {
        return (Position.allCases.reduce(0) { $0 + self[$1].count }) == Rank.allCases.count
    }
}


