//
//  Suit.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Suit: Int, Comparable, CaseIterable {
    case clubs = 0, diamonds, hearts, spades
    public init?(_ suit: String) {
        switch (suit.lowercased()) {
        case "c", "club", "clubs": self = .clubs
        case "d", "diamond", "diamonds": self = .diamonds
        case "h", "heart", "hearts": self = .hearts
        case "s", "spade", "spades": self = .spades
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
    public var shortDescription : String {
        switch self {
        case .clubs: return "\u{2663}"
        case .diamonds: return "\u{2666}"
        case .hearts: return "\u{2665}"
        case .spades: return "\u{2660}"
        }
    }
}
