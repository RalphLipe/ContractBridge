//
//  Vulnerable.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public typealias Vulnerable = Set<Pair>

public extension Vulnerable {
    func contains(_ position: Position ) -> Bool { return contains(position.pair) }
}

public extension Vulnerable {
    static let none: Set<Pair> = []
    static let all: Set<Pair> = [.ns, .ew]
    static let ns: Set<Pair> = [.ns]
    static let ew: Set<Pair> = [.ew]
    
    init?(_ vulnerableText: String) {
        switch (vulnerableText.lowercased()) {
        case "none", "love", "-":   self = Vulnerable.none
        case "ns", "n/s":           self = Vulnerable.ns
        case "ew", "e/w":           self = Vulnerable.ew
        case "all", "both":         self = Vulnerable.all
        default: return nil
        }
    }
    
    // This is used by string interpolation.
    internal var shortDescription: String {
        if contains(.ns) {
            return contains(.ew) ? "All" : "NS"
        } else {
            return contains(.ew) ? "EW" : "None"
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ vulnerable: Vulnerable, style: Suit.StringStyle = .symbol) {
        if style == .name {
            appendLiteral(vulnerable.description)
        } else {
            appendLiteral(vulnerable.shortDescription)
        }
    }
}
