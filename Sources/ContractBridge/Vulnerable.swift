//
//  Vulnerable.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

// It is important that the enum stays in this order for proper vulnerability base
// on board numbers.
public enum Vulnerable: Int, Codable {
    case none = 0, ns, ew, all
}

public extension Vulnerable {
    func isVul(_ direction: Direction ) -> Bool {
        return isVul(direction.pairDirection)
    }
    func isVul(_ pairDirection: PairDirection) -> Bool {
        if self == .none { return false }
        if self == .all { return true }
        if self == .ns { return pairDirection == .ns }
        assert(self == .ew)
        return pairDirection == .ew
    }
}

public extension Vulnerable {
    init?(from: String) {
        switch (from.lowercased()) {
            case "none", "love", "-":   self = Vulnerable.none
            case "ns", "n/s":           self = Vulnerable.ns
            case "ew", "e/w":           self = Vulnerable.ew
            case "all", "both":         self = Vulnerable.all
            default: return nil
        }
    }
    
    init(boardNumber: Int) {
        let vulOffset = (boardNumber - 1) / 4
        self.init(rawValue: (boardNumber - 1 + vulOffset) % 4)!
    }
    
    // This is used by string interpolation.
    internal var shortDescription: String {
        switch self {
            case .none: return "None"
            case .ns:   return "NS"
            case .ew:   return "EW"
            default:    return "All"
        }
    }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ vulnerable: Vulnerable, style: ContractBridge.Style = .symbol) {
        if style == .name {
            appendLiteral(vulnerable.shortDescription)
        } else {
            appendLiteral(vulnerable.shortDescription)
        }
    }
}
