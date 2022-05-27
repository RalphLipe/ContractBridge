//
//  Strain.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Strain: Int, Comparable, CaseIterable {
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
    
    public var shortDescription : String {
        if let suit = self.suit {
            return "\(suit)"
        } else {
            return "NT"
        }
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

extension String.StringInterpolation {
    mutating func appendInterpolation(_ strain: Strain, style: Suit.StringStyle = .symbol) {
        if let suit = strain.suit {
            appendInterpolation(suit, style: style)
        } else {
            switch style {
            case .character, .symbol: appendLiteral("NT")
            case .name: appendLiteral("no trump")
            }
        }
    }
}
