//
//  Strain.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Strain: Int, Comparable, CaseIterable, Codable {
    case clubs = 0, diamonds, hearts, spades, noTrump
    
    public init(suit: Suit?) {
        if let suit = suit {
            self.init(rawValue: suit.rawValue)!
        } else {
            self = .noTrump
        }
    }
    
    public static func < (lhs: Strain, rhs: Strain) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public var suit: Suit? {
        assert(Suit.clubs.rawValue == Strain.clubs.rawValue)
        assert(Suit.diamonds.rawValue == Strain.diamonds.rawValue)
        assert(Suit.hearts.rawValue == Strain.hearts.rawValue)
        assert(Suit.spades.rawValue == Strain.spades.rawValue)
        
        return self == .noTrump ? nil : Suit(rawValue: self.rawValue)!
    }
    
    public var trickScore: Int {
        switch self {
        case .noTrump, .spades, .hearts:  return 30
        case .clubs, .diamonds:           return 20
        }
    }
    
    public var firstTrickScore: Int {
        return (self == .noTrump) ? 40 : trickScore
    }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ strain: Strain, style: ContractBridge.Style = .symbol) {
        var s: String
        if let suit = strain.suit {
            s = "\(suit, style: style)"
        } else {
            s = style == .name ? "no trump" : "NT"
        }
        appendLiteral(s)
    }
}
