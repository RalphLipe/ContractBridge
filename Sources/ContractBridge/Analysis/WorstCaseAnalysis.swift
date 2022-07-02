//
//  WorstCaseAnalysis.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation

// Declarer plays all cards from highest to lowest.  Defenders
public struct WorstCaseAnalysis {
    private var suitHolding: SuitHolding
    private let declaring: (Position, Position)
    private let defending: (Position, Position)
    
    public static func analyze(suitLayout: SuitLayout, declaringPair: Pair) -> Int {
        return WorstCaseAnalysis(suitLayout: suitLayout, declaringPair: declaringPair).bestLead()
    }
    
    public static func isAllWinners(suitLayout: SuitLayout, declaringPair: Pair) -> Bool {
        let analyzer = WorstCaseAnalysis(suitLayout: suitLayout, declaringPair: declaringPair)
        return analyzer.bestLead() == analyzer.remainingDeclarerTricks
    }
    
    private init(suitLayout: SuitLayout, declaringPair: Pair) {
        self.suitHolding = SuitHolding(suitLayout: suitLayout)
        self.declaring = declaringPair.positions
        self.defending = declaringPair.opponents.positions
    }
    
    internal var remainingDeclarerTricks: Int {
        return max(suitHolding[declaring.0].count, suitHolding[declaring.1].count)
    }
    
    private func followLowDefense(position: Position, declarerPlay: RankRange, defensePlay: RankRange) -> Int {
        var numTricks = 0
        var defenseHighest = defensePlay
        if suitHolding[position].isEmpty {
            numTricks = bestLead()
        } else {
            let lowRankRange = suitHolding[position].lowest()
            let lowestRank = lowRankRange.play()
            numTricks = bestLead()
            lowRankRange.undoPlay(rank: lowestRank)
            if lowRankRange > defenseHighest { defenseHighest = lowRankRange }
        }
        if defenseHighest < declarerPlay { numTricks += 1 }
        return numTricks
    }
    
    
    private func defendHigh(from position: Position, played: RankRange) -> Int {
        if suitHolding[position].isEmpty {
            return remainingDeclarerTricks + 1  // Declarer will win this trick plus all others
        } else {
            let winnerRange = suitHolding[position].lowest(cover: played)
            let winnerRank = winnerRange.play()
            let numTricks = followLowDefense(position: position.partner, declarerPlay: played, defensePlay: winnerRange)
            winnerRange.undoPlay(rank: winnerRank)
            return numTricks
        }
    }
    
    private func defendAgainst(played: RankRange) -> Int {
        return min(defendHigh(from: defending.0, played: played), defendHigh(from: defending.1, played: played))
    }
    
  
    private func bestLead() -> Int {
        var leadFrom: Position = declaring.0
        if suitHolding[leadFrom].isEmpty {
            if suitHolding[declaring.1].isEmpty { return 0 }
            leadFrom = declaring.1
        } else if !suitHolding[declaring.1].isEmpty {
            let max0 = suitHolding[declaring.0].highest().promotedRange
            let max1 = suitHolding[declaring.1].highest().promotedRange
            assert(leadFrom == declaring.0)
            // Lead from the high side.  If equally high cards then lead from the short side
            if max0.upperBound < max1.upperBound || (max0 == max1 && suitHolding[declaring.0].count > suitHolding[declaring.1].count) {
                leadFrom = declaring.1
            }
        }
        let playRankRange = suitHolding[leadFrom].highest()
        let playRank = playRankRange.play()
        let numTricks: Int
        if suitHolding[leadFrom.partner].isEmpty {
            numTricks = defendAgainst(played: playRankRange)
        } else {
            let lowRankRange = suitHolding[leadFrom.partner].lowest()
            let lowestRank = lowRankRange.play()
            numTricks = defendAgainst(played: playRankRange)
            lowRankRange.undoPlay(rank: lowestRank)
        }
        playRankRange.undoPlay(rank: playRank)
        return numTricks
    }
}
