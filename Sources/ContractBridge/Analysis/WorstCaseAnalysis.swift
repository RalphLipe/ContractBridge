//
//  WorstCaseAnalysis.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation

// This evaluates a card combination and assumes the worst case for opponents - that is that
// all the ranks will be in one hand.  Regardless of the suit layout provided, all of the
// opponent's ranks will be placed in a single hand for evaluation.  Any nil ranks will not be
// considered.

public struct WorstCaseAnalysis {
    
    // NOTE:  In this analysis, the declaing side is limited to the number of ranks in the longest hand.  For the defense
    // the worst case of all ranks being in a single hand is assumed.  This function could be modified easily to limit
    // defense to the maximum of the longest side if desired, but as of now there is no need for this functionality.
    public static func analyze(suitLayout: SuitLayout, declaringPair: Pair) -> (tricksTaken: Int, maxTricksPossible: Int) {
        let declarerPositions = declaringPair.positions
        let maxTricks = max(suitLayout.countFor(position: declarerPositions.0),
                            suitLayout.countFor(position: declarerPositions.0))
        var declarerHolding: Set<Rank> = suitLayout.ranksFor(position: declarerPositions.0).union(suitLayout.ranksFor(position: declarerPositions.1))
        while declarerHolding.count > maxTricks {
            let min = declarerHolding.min()!
            declarerHolding.remove(min)
        }
        let defensePositions = declaringPair.opponents.positions
        var defenseHolding: Set<Rank> = suitLayout.ranksFor(position: defensePositions.0).union(suitLayout.ranksFor(position: defensePositions.1))
        var numTricks = 0
        while declarerHolding.count > 0 && defenseHolding.count > 0 {
            let declarerPlay = declarerHolding.max()!
            var defensePlay: Rank? = nil
            for rank in defenseHolding {
                // We will use this rank if it's the only one we've seen or if it wins and and lower than a current winnner or
                // if there is not a winner and this rank is lower than the current defense play
                if defensePlay == nil ||
                    ((rank > declarerPlay || defensePlay! < declarerPlay) && rank < defensePlay!) {
                    defensePlay = rank
                }
            }
            if declarerPlay > defensePlay! { numTricks += 1 }
            declarerHolding.remove(declarerPlay)
            defenseHolding.remove(defensePlay!)
        }
        return (tricksTaken: numTricks + declarerHolding.count, maxTricksPossible: maxTricks)
    }
    
    public static func isAllWinners(suitLayout: SuitLayout, declaringPair: Pair) -> Bool {
        let result = WorstCaseAnalysis.analyze(suitLayout: suitLayout, declaringPair: declaringPair)
        return result.maxTricksPossible == result.tricksTaken
    }
}
