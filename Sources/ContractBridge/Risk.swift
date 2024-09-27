//
//  Risk.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Risk: CaseIterable, Codable {
    case undoubled, doubled, redoubled
    
    init?(from: String) {
        switch from.lowercased() {
        case "":   self = .undoubled
        case "x":  self = .doubled
        case "xx": self = .redoubled
        default: return nil
        }
    }
    
    var insultBonus: Int {
        switch self {
        case .undoubled: return 0
        case .doubled:   return 50
        case .redoubled: return 100
        }
    }
    
    func overTrickScore(strain: Strain, isVulnerable: Bool) -> Int {
        var score = strain.trickScore
        if self != .undoubled {
            score = 100
            if isVulnerable { score *= 2 }
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
    
    func penaltyScore(underTrickCount: Int, isVulnerable: Bool) -> Int {
        assert(underTrickCount > 0) // Functino expects a positive count of under tricks
        var score: Int
        if self == .undoubled {
            score = isVulnerable ? -100 : -50
            score *= underTrickCount
        } else {
            let downScores: [Int] = isVulnerable ? Risk.vulDoubledDown : Risk.nonVulDoubleDown
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

extension String.StringInterpolation {
    mutating func appendInterpolation(_ risk: Risk, style: ContractBridge.Style = .symbol) {
        if style == .name {
            switch risk {
            case .undoubled: appendLiteral("undoubled")
            case .doubled:   appendLiteral("doubled")
            case .redoubled: appendLiteral("redoubled")
            }
        } else if risk == .doubled {
            appendLiteral("X")
        } else if risk == .redoubled {
            appendLiteral("XX")
        }
    }
}
