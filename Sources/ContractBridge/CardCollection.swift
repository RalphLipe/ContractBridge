//
//  CardCollection.swift
//  
//
//  Created by Ralph Lipe on 3/10/22.
//

import Foundation


enum CardCollectionError: Error {
    case tooManySuits
    case invalidCardCharacter(_ character: Character)
    case duplicateCard
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
    
   
    public func suitCards(_ suit: Suit) -> CardCollection {
        var suitCards: [Card] = []
        for card in self.cards {
            if card.suit == suit {
                suitCards.append(card)
            }
        }
        return CardCollection(suitCards)
    }
    
    public var points: Int {
        var points = 0
        for card in self.cards {
            points += card.points
        }
        return points
    }
    
    public func validate() throws -> Void {
        // TODO:  This will not work if "x" allowed for rank
        if Set<Card>(self.cards).count < self.cards.count {
            throw CardCollectionError.duplicateCard
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

