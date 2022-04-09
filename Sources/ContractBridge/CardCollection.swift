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
    private var cards: [Card]
    
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
    
    public init<S>(_ cards: S) where S : Sequence, Card == S.Element {
        self.cards = Array(cards)
    }
    
    public init(from: String, allowDuplicates: Bool = false, requireFullHand: Bool = false, sort: Bool = true) throws {
        self.cards = []
        if from != "-" {
            var suit = Suit.spades
            for c in from {
                if c == "." {
                    guard let nextSuit = suit.nextLower else {
                        throw CardCollectionError.tooManySuits
                    }
                    suit = nextSuit
                } else {
                    guard let rank = Rank(from: String(c)) else {
                        throw CardCollectionError.invalidCardCharacter(c)
                    }
                    self.cards.append(Card(rank, suit))
                }
            }
            try validate(allowDuplicates: allowDuplicates, requireFullHand: requireFullHand)
            if sort { self.sortHandOrder() }
        }
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
        if cards.count == 0 { return "-" }
        let s = NSMutableString(capacity: cards.count + 3)
        var suit: Suit? = Suit.spades
        while suit != nil {
            var suitCards = suitCards(suit!)
            suitCards.sortHandOrder()
            for card in suitCards {
                s.append(card.rank.shortDescription)
            }
            suit = suit!.nextLower
            if suit != nil { s.append(".") }
        }
        return s as String
    }
    
    public mutating func sortHandOrder() {
        cards.sort()
        cards.reverse()
    }
 
    public func suitCards(_ suit: Suit) -> CardCollection {
        return CardCollection(self.filter { $0.suit == suit })
    }
    
    public var highCardPoints: Int {
        var points = 0
        for card in self.cards { points += card.highCardPoints }
        return points
    }
    
    public func validate(allowDuplicates: Bool = false, requireFullHand: Bool = false) throws -> Void {
        if requireFullHand && self.count != 13 {
            throw CardCollectionError.notFullHand(cardInHand: self.count)
        }
        if allowDuplicates == false {
            var seenCards = Set<Card>()
            for card in self.cards {
                if seenCards.insert(card).inserted == false {
                    throw CardCollectionError.duplicateCard(card)
                }
            }
        }
    }

    public mutating func removeFirst(_ card: Card) -> Card? {
        if let i = cards.firstIndex(of: card) {
            return cards.remove(at: i)
        }
        return nil
    }
    

    // Methods supported by Array<Card> that need to be passed to underlying array
    public mutating func removeFirst() -> Card { return cards.removeFirst() }
    public mutating func removeLast() -> Card { return cards.removeLast() }
    
    public mutating func append(_ card: Card) {
        cards.append(card)
    }
    
    public mutating func insert(_ card: Card, at: Int) {
        cards.insert(card, at: at)
    }

    public mutating func insert<C>(contentsOf newElements: C, at i: Int) where C : Collection, Card == C.Element {
        cards.insert(contentsOf: newElements, at: i)
    }
    
    public mutating func remove(at: Int) -> Card { return cards.remove(at: at) }
    public mutating func removeLast(_ k: Int) { cards.removeLast(k) }

    public mutating func append<S>(contentsOf newElements: S) where Element == S.Element, S : Sequence {
        cards.append(contentsOf: newElements)
    }
}

extension CardCollection: RandomAccessCollection, MutableCollection, Sequence {
    public subscript(position: Int) -> Card {
        get {
            return cards[position]
        }
        set(newValue) {
            cards[position] = newValue
        }
    }
    
    public var startIndex: Int { return cards.startIndex }
    public var endIndex: Int { return cards.endIndex }

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


