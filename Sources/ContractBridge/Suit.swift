//
//  Suit.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Suit: Int, Comparable, CaseIterable {
    case clubs = 0, diamonds, hearts, spades
    public init?(from suitText: String) {
        switch (suitText.lowercased()) {
        case "c", "club", "clubs", "\u{2663}": self = .clubs
        case "d", "diamond", "diamonds", "\u{2666}": self = .diamonds
        case "h", "heart", "hearts", "\u{2665}": self = .hearts
        case "s", "spade", "spades", "\u{2660}": self = .spades
        default: return nil
        }
    }
    public init?(strain: Strain) {
        if strain == .noTrump { return nil }
        self.init(rawValue: strain.rawValue)
    }
    public var nextLower: Suit? {
        return Suit(rawValue: self.rawValue-1)
    }
    public var nextHigher: Suit? {
        return Suit(rawValue: self.rawValue+1)
    }
    public static func < (lhs: Suit, rhs: Suit) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ suit: Suit, style: ContractBridge.Style = .symbol) {
        var s: String
        switch style {
        case .symbol:
            switch suit {
            case .clubs:    s = "\u{2663}"
            case .diamonds: s = "\u{2666}"
            case .hearts:   s = "\u{2665}"
            case .spades:   s = "\u{2660}"
            }
        case .character:
            switch suit {
            case .clubs:    s = "C"
            case .diamonds: s = "D"
            case .hearts:   s = "H"
            case .spades:   s = "S"
            }
        case .name:
            switch suit {
            case .clubs:    s = "clubs"
            case .diamonds: s = "diamonds"
            case .hearts:   s = "hearts"
            case .spades:   s = "spades"
            }
        }
        appendLiteral(s)
    }
}
