//
//  Hand.swift
//  
//
//  Created by Ralph Lipe on 3/10/22.
//

import Foundation


enum HandSyntaxError: Error {
    case tooManySuitsInHand
    case invalidCardCharacter(_ character: Character)
}

public struct Hand: Codable {
    public var cards: [Card]
    
    public init() {
        self.cards = []
    }
    public init(_ cards: [Card]) {
        self.cards = cards
    }
    
    public init(fromSerialized: String) throws {
        self.cards = []
        var suit = Suit.spades
        for c in fromSerialized {
            if c == "." {
                guard let nextSuit = suit.nextLower else {
                    throw HandSyntaxError.tooManySuitsInHand
                }
                suit = nextSuit
            } else {
                guard let card = Card(suit: suit, rankText: String(c)) else {
                    throw HandSyntaxError.invalidCardCharacter(c)
                }
                self.cards.append(card)
            }
        }
    }
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(fromSerialized: s)
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialized)
    }

    public var serialized: String {
        var s = ""
        var suit: Suit? = Suit.spades
        while suit != nil {
            for card in suitCards(suit!) {
                s += card.shortDescription
            }
            suit = suit!.nextLower
            if suit != nil { s += "." }
        }
        return s
    }
    
    func suitCards(_ suit: Suit) -> [Card] {
        var suitCards: [Card] = []
        for card in self.cards {
            if card.suit == suit {
                suitCards.append(card)
            }
        }
        return suitCards
    }
    
    var points: Int {
        var points = 0
        for card in self.cards {
            points += card.points
        }
        return points
    }
    
}
