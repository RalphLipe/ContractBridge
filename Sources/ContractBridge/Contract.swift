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
            let contractScore = (strain.firstTrickScore + (strain.trickScore * (level - 1))) * penalty.makingTrickMultiplier
            let overTrickScore = (tricksTaken - level - 6) * penalty.overTrickScore(strain: strain, vulnerable: vulnerable)
            let makingBonus = makingBonus(contractScore: contractScore, vulnerable: vulnerable)
            let slamBonus = slamBonus(vulnerable: vulnerable)
            let score = contractScore + overTrickScore + makingBonus + slamBonus + penalty.insultBonus
            return score
        } else {
            return penalty.penaltyScore(underTrickCount: -(tricksTaken - level - 6), vulnerable: vulnerable)
        }
    }
        
    private func slamBonus(vulnerable: Bool) -> Int {
        switch level {
        case 6: return vulnerable ? 750 : 500
        case 7: return vulnerable ? 1500 : 1000
        default: return 0
        }
    }
    
    private func makingBonus(contractScore: Int, vulnerable: Bool) -> Int {
        return contractScore < 100 ? 50 : vulnerable ? 500 : 300
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

