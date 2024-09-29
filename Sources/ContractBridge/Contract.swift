//
//  Contract.swift
//
//
//  Created by Ralph Lipe on 3/9/22.
//

public enum ContractError: Error {
    case invalidLevel
    case invalidStrain
    case invalidRisk
}

public struct Contract: Codable {
    public let level: Int
    public let strain: Strain
    public let risk: Risk
    
    public init(level: Int, strain: Strain, risk: Risk) {
        assert(level >= 0 && level <= 7)
        self.level = level
        self.strain = strain
        self.risk = risk
    }

    // Create a passed-out contract
    public init() {
        self.level = 0
        self.strain = .noTrump
        self.risk = .undoubled
    }
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(from: s)
    }
    
    public init(from: String) throws {
        var s = from.lowercased()
        if s == "pass" {
            self.init()
            return
        }
        if s.count < 2 { throw ContractError.invalidLevel }
        guard let level = Int(String(s.first!)), level > 0 && level <= 7 else { throw ContractError.invalidLevel }
        s.removeFirst()
        var strain: Strain? = nil
        if s.starts(with: "nt") {
            strain = .noTrump
            s.removeFirst(2)
        } else {
            guard let suit = Suit(from: String(s.first!)) else { throw ContractError.invalidStrain }
            strain = Strain(suit: suit)
            s.removeFirst()
        }
        guard let risk = Risk(from: s), let strain = strain else { throw ContractError.invalidRisk }
        self.init(level: level, strain: strain, risk: risk)
    }

    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialize())
    }
    
    public func serialize() -> String {
        return "\(self, style: .character)"
    }
    
    public func score(isVulnerable: Bool, tricksTaken: Int) -> Int {
        if isPassedOut { return 0 }
        if tricksTaken >= level + 6 {     // Contract was made
            let contractScore = (strain.firstTrickScore + (strain.trickScore * (level - 1))) * risk.makingTrickMultiplier
            let overTrickScore = (tricksTaken - level - 6) * risk.overTrickScore(strain: strain, isVulnerable: isVulnerable)
            let makingBonus = makingBonus(contractScore: contractScore, isVulnerable: isVulnerable)
            let slamBonus = slamBonus(isVulnerable: isVulnerable)
            let score = contractScore + overTrickScore + makingBonus + slamBonus + risk.insultBonus
            return score
        } else {
            return risk.penaltyScore(underTrickCount: -(tricksTaken - level - 6), isVulnerable: isVulnerable)
        }
    }
        
    private func slamBonus(isVulnerable: Bool) -> Int {
        switch level {
        case 6: return isVulnerable ? 750 : 500
        case 7: return isVulnerable ? 1500 : 1000
        default: return 0
        }
    }
    
    private func makingBonus(contractScore: Int, isVulnerable: Bool) -> Int {
        return contractScore < 100 ? 50 : isVulnerable ? 500 : 300
    }
    
    public var isPassedOut: Bool { return level == 0 }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ contract: Contract, style: ContractBridge.Style = .symbol) {
        if contract.isPassedOut {
            appendLiteral("pass")
        } else {
            if style == .name {
                appendLiteral("\(contract.level) \(contract.strain, style: style) \(contract.risk, style: style)")
            } else {
                appendLiteral("\(contract.level)\(contract.strain, style: style)\(contract.risk, style: style)")
            }
        }
    }
}
