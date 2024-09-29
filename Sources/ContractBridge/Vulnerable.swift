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
    
    public func isVul(_ direction: Direction ) -> Bool {
        return isVul(direction.pairDirection)
    }
    public func isVul(_ pair: PairDirection) -> Bool {
        return (self == .all) || (self == .ns && pair == .ns) || (self == .ew && pair == .ew)
    }
    
    init?(from: String) {
        switch (from.lowercased()) {
            case "none", "love", "-":   self = Vulnerable.none
            case "ns", "n/s":           self = Vulnerable.ns
            case "ew", "e/w":           self = Vulnerable.ew
            case "all", "both":         self = Vulnerable.all
            default: return nil
        }
    }
    
    // TODO: DUPLICATED CODE!  TRY TO GET RID OF THIS!
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let value = Self(from: stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot initialize \(Self.self) from invalid String value \(stringValue)")
        }
        self = value
    }
 
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self, style: .character)")
    }
    // TODO: END OF DUPLICATED CODE
    
    
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
        appendLiteral(vulnerable.shortDescription)
    }
}
