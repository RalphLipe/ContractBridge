//
//  CardCollection.swift
//  
//
//  Created by Ralph Lipe on 3/10/22.
//

import Foundation


public enum CardCollectionError: Error {
    case tooManySuits
    case invalidCardCharacter(_ character: Character)
    case duplicateCard(_ card: Card)
    case notFullHand(cardInHand: Int)
}

public struct CardCollection: Codable {

    private(set) public var cards: [Card]
    
    public init() {
        self.cards = []
    }
    
    public init(numberOfDecks: Int) {
        self.cards = []
        var i = 0
        while i < numberOfDecks {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    self.cards.append(Card(rank, suit))
                }
            }
            i += 1
        }
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
                    throw CardCollectionError.tooManySuits
                }
                suit = nextSuit
            } else {
                guard let rank = Rank(String(c)) else {
                    throw CardCollectionError.invalidCardCharacter(c)
                }
                self.cards.append(Card(rank, suit))
            }
        }
        try validate()
        self.sortHandOrder()
    }
    
    public mutating func sortHandOrder() {
        cards.sort()
        cards.reverse()
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
        let s = NSMutableString(capacity: cards.count + 3)
        var suit: Suit? = Suit.spades
        while suit != nil {
            for card in suitCards(suit!) {
                s.append(card.rank.shortDescription)
            }
            suit = suit!.nextLower
            if suit != nil { s.append(".") }
        }
        return s as String
    }
    
   
    public func suitCards(_ suit: Suit) -> CardCollection {
        return CardCollection(self.filter { $0.suit == suit })
    }
    
    public var points: Int {
        var points = 0
        for card in self.cards { points += card.points }
        return points
    }
    
    public func validate(requireFullHand: Bool = false) throws -> Void {
        if requireFullHand && self.count != 13 {
            throw CardCollectionError.notFullHand(cardInHand: self.count)
        }
        var seenCards = Set<Card>()
        for card in self.cards {
            if seenCards.insert(card).inserted == false {
                throw CardCollectionError.duplicateCard(card)
            }
        }
    }
    
    public mutating func append(_ card: Card) {
        cards.append(card)
    }
    
    public mutating func insert(_ card: Card, at: Int) {
        cards.insert(card, at: at)
    }
    
    public mutating func remove(at: Int) -> Card {
        return cards.remove(at: at)
    }
    
    public mutating func shuffle() {
        cards.shuffle()
    }
}

extension CardCollection: Collection {
    // The upper and lower bounds of the collection, used in iterations
    public var startIndex: Int { return cards.startIndex }
    public var endIndex: Int { return cards.endIndex }

    public subscript(index: Int) -> Card {
        get { return cards[index] }
    }
    public func index(after i: Int) -> Int {
        return cards.index(after: i)
    }
}

extension CardCollection: ExpressibleByArrayLiteral {
    public init(arrayLiteral: Card...) {
        self.init()
        for card in arrayLiteral {
            self.append(card)
        }
    }
}

