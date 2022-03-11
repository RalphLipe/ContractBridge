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
    
    public init(from: String) throws {
        self.cards = []
        var suit = Suit.spades
        for c in from {
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
        sort()
    }
    
    mutating public func sort() -> Void {
        cards = cards.sorted { (lhc: Card, rhc: Card) -> Bool in return lhc > rhc }
    }
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(from: s)
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
                s += card.rank.shortDescription
            }
            suit = suit!.nextLower
            if suit != nil { s += "." }
        }
        return s
    }
    
    public func suitCards(_ suit: Suit) -> [Card] {
        var suitCards: [Card] = []
        for card in self.cards {
            if card.suit == suit {
                suitCards.append(card)
            }
        }
        return suitCards
    }
    
    public var points: Int {
        var points = 0
        for card in self.cards {
            points += card.points
        }
        return points
    }
    
}
