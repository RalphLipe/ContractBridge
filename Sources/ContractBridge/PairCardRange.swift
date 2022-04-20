//
//  PairCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



class PairCardRange {
    let suit: Suit
    var hands: [CompositeCardRange]
    let pair: PairPosition
    private var opponentPlayed: [CountedCardRange]
    private let handRanges: [[CountedCardRange]]
    

    init(allRanges: [CountedCardRange], pair: PairPosition) {
        self.pair = pair
        self.suit = allRanges.first!.suit
        // Make a copy of all of the ranges.  Then create new copies for each hand of the pair while
        // using the opponentPlayed solid ranges in each array
        var handRanges: [[CountedCardRange]] = []
        var hands: [CompositeCardRange] = []
        
        self.opponentPlayed = Array(allRanges.map { $0.copy(count: 0) })
        for _ in 0...1 {
            // For each hand array, copy the opponentPlayed range for opponent ranges and make a new
            // copy for each range that is owned by this pair (allowing for individual counts per position)
            // Then construct a single CompositeRange that spans only the ranges for this pair for the "hand"
            handRanges.append(Array(self.opponentPlayed.map { $0.pair == pair ? $0.copy() : $0 }))
            hands.append(CompositeCardRange(allRanges: handRanges.last!, pair: pair))
        }
        self.handRanges = handRanges
        self.hands = hands
    }

    private func positionIndex(_ position: Position) -> Int {
        assert(position.pairPosition == pair)
        return position == .north || position == .east ? 0 : 1
    }
    
    public func hand(_ position: Position) -> CompositeCardRange {
        return hands[positionIndex(position)]
    }
  
    public func opponentPlayed(_ rankRange: CountedCardRange, played: Bool) -> Void {
        let adjustCount = played ? 1 : -1
        self.opponentPlayed[rankRange.index].count += adjustCount
    }
    
    /*
    private var winningRankIndex: Int {
        let i = self.opponentPlayed.endIndex - 1
        while i > 0 {
            let rankRange = self.opponentPlayed[i]
            if rankRange.pair != self.pair && rankRange.count != rankRange.range.count {
                return i
            }
        }
        return 0
    }
    
    var winningRank: ClosedRange<Rank> {
        return self.opponentPlayed[self.winningRankIndex].range
    }
    */

    
    
    func choices(_ position: Position) -> RangeChoices {
        var group: [CountedCardRange] = []
        var groupHasCards = false
        var allRanges: [CompositeCardRange] = []
        for range in handRanges[self.positionIndex(position)] {
            if range.pair == self.pair || range.count == range.ranks.count {
                group.append(range)
                groupHasCards = groupHasCards || (range.pair == self.pair && range.count > 0)
            } else {
                if groupHasCards { allRanges.append(CompositeCardRange(allRanges: group, pair: pair))}
                group = []
                groupHasCards = false
            }
        }
        if groupHasCards { allRanges.append(CompositeCardRange(allRanges: group, pair: self.pair))}
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
    
    //var numWinningRanks: Int { return win?.count ?? 0 }
}
