//
//  Contract.swift
//
//
//  Created by Ralph Lipe on 3/9/22.
//

public struct Contract {
    public let level: Int
    public let strain: Strain
    public let penalty: Penalty
    public let declarer: Position
    
    public init(level: Int, strain: Strain, penalty: Penalty, declarer: Position) {
        assert(level >= 0 && level <= 7)
        self.level = level
        self.strain = strain
        self.penalty = penalty
        self.declarer = declarer
    }

    // Create a passed-out contract
    public init() {
        self.level = 0
        self.strain = .noTrump
        self.penalty = .undoubled
        self.declarer = .north
    }
    
    public func score(vulnerability: Vulnerability, tricksTaken: Int) -> Int {
        if isPassedOut { return 0 }
        let vulnerable = vulnerability.isVulnerable(declarer)
        if tricksTaken >= level + 6 {     // Contract was made
            let makingScore = (strain.firstTrickScore + (strain.trickScore * (level - 1))) * penalty.makingTrickMultiplier
            let overTrickScore = (tricksTaken - level - 6) * penalty.overTrickScore(strain: strain, vulnerable: vulnerable)
            let score = makingScore + overTrickScore + penalty.insultBonus + makingBonus(vulnerable: vulnerable)
            return score
        } else {
            return penalty.penaltyScore(underTrickCount: -(tricksTaken - level - 6), vulnerable: vulnerable)
        }
    }
        
    
    private func makingBonus(vulnerable: Bool) -> Int {
        let gameBonus = vulnerable ? 500 : 300
        switch level {
        case 1, 2: return 50
        case 3: return (strain == .noTrump) ? gameBonus : 50
        case 4: return (strain == .spades || strain == .hearts) ? gameBonus : 50
        case 5: return gameBonus
        case 6: return vulnerable ? 750 + gameBonus : 500 + gameBonus
        case 7: return vulnerable ? 1500 + gameBonus : 1000 + gameBonus
        default: return 0
        }
    }
    
    public var shortDescription: String {
        get {
            if isPassedOut {
                return "passed out"
            } else {
                if penalty == .undoubled {
                    return "\(level) \(strain.shortDescription) \(declarer.shortDescription)"
                } else {
                    return "\(level) \(strain.shortDescription) \(penalty.shortDescription) \(declarer.shortDescription)"
                }
            }
        }
    }
    
    public var isPassedOut: Bool { return level == 0 }
}

