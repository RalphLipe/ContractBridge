//
//  File.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Penalty: CaseIterable {
    case undoubled, doubled, redoubled
    
    public var shortDescription: String {
        switch self {
        case .undoubled: return ""
        case .doubled:   return "X"
        case .redoubled: return "XX"
        }
    }
    var insultBonus: Int {
        switch self {
        case .undoubled: return 0
        case .doubled:   return 50
        case .redoubled: return 100
        }
    }
    func overTrickScore(strain: Strain, vulnerable: Bool) -> Int {
        var score = strain.trickScore
        if self != .undoubled {
            score = 100
            if vulnerable { score *= 2 }
            if self == .redoubled { score *= 2 }
        }
        return score
    }
    var makingTrickMultiplier: Int {
        switch self {
        case .undoubled: return 1
        case .doubled:   return 2
        case .redoubled: return 4
        }
    }
    
    // These arrays contain the TOTAL score for 1, 2, and 3 under tricks for vulnerable and non-vunlerable
    // contracts.  For tricks 4-13 down, the penalty is the same regardless of vulnerablity at 300 per trick
    static private var vulDoubledDown = [-200, -500, -800]
    static private var nonVulDoubleDown = [-100, -300, -500]
    
    func penaltyScore(underTrickCount: Int, vulnerable: Bool) -> Int {
        assert(underTrickCount > 0) // Functino expects a positive count of under tricks
        var score: Int
        if self == .undoubled {
            score = vulnerable ? -100 : -50
            score *= underTrickCount
        } else {
            let downScores: [Int] = vulnerable ? Penalty.vulDoubledDown : Penalty.nonVulDoubleDown
            let i = min(3, underTrickCount) - 1
            score = downScores[i]
            if underTrickCount >= 4 {
                score -= ((underTrickCount - 3) * 300)
            }
            if self == .redoubled { score *= 2 }
        }
        return score
    }
}

