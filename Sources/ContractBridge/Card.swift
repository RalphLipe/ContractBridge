//
//  Card.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public struct Card : Comparable, Codable, Hashable, CustomStringConvertible {
    public let suit: Suit
    public let rank: Rank
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        var s = try decoder.decode(String.self)
        rank = Rank(String(s.removeFirst()))!
        suit = Suit(String(s.removeFirst()))!
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(rank.shortDescription + suit.shortDescription)
    }

    public init(_ rank: Rank, _ suit: Suit) {
        self.suit = suit
        self.rank = rank
    }
    
    public init?(suit: Suit, rankText: String) {
        if let rank = Rank(rankText) {
            self.init(rank, suit)
        } else {
            return nil
        }
    }

    public var shortDescription: String {
        return "\(rank.shortDescription)\(suit.shortDescription)"
    }
    
    public var points: Int {
        switch self.rank {
        case .ace:   return 4
        case .king:  return 3
        case .queen: return 2
        case .jack:  return 1
        default:     return 0
        }
    }
    
    //  BUGUBUG -- is this the right place to have this
    public static func newDeck() -> [Card] {
        var deck = Array<Card>()
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank, suit))
            }
        }
        return deck
    }
    
    public static func < (lhs: Card, rhs: Card) -> Bool {
        if (lhs.suit == rhs.suit) {
            return lhs.rank < rhs.rank
        } else {
            return lhs.suit < rhs.suit
        }
    }
    
    public var description: String {
        return "\(rank) of \(suit)"
    }
}


public extension Array where Element == Card {
    init(decks: Int) {
        self.init()
        var i = 0;
        while i < decks {
            self += Card.newDeck()
            i += 1
        }
    }

    func suitCards(_ suit: Suit) -> [Card] {
        var suitCards: [Card] = []
        for card in self {
            if card.suit == suit {
                suitCards.append(card)
            }
        }
        return suitCards
    }
    var points: Int {
        var points = 0
        for card in self {
            points += card.points
        }
        return points
    }
}

