//
//  CardArray.swift
//  
//
//  Created by Ralph Lipe on 3/10/22.
//

import Foundation

public enum CardArrayError: Error {
    case tooManySuits
    case invalidCardCharacter(_ character: Character)
    case duplicateCard(_ card: Card)
    case notFullHand(cardInHand: Int)
}



extension Array where Element == Card {
    public static func fromSerialized(_ from: String, allowDuplicates: Bool = false, requireFullHand: Bool = false, sort: Bool = true) throws -> [Card] {
        var cards: [Card] = []
        if from != "-" {
            var suit = Suit.spades
            for c in from {
                if c == "." {
                    guard let nextSuit = suit.nextLower else {
                        throw CardArrayError.tooManySuits
                    }
                    suit = nextSuit
                } else {
                    guard let rank = Rank(from: String(c)) else {
                        throw CardArrayError.invalidCardCharacter(c)
                    }
                    cards.append(Card(rank, suit))
                }
            }
            try cards.validate(allowDuplicates: allowDuplicates, requireFullHand: requireFullHand)
            if sort { cards.sortHandOrder() }
        }
        return cards
    }
    
    public static func newDeck() -> [Card] { return Card.allCases.map { $0 } }

    public var serialized: String {
        if count == 0 { return "-" }
        let s = NSMutableString(capacity: count + 3)
        var suit: Suit? = Suit.spades
        while suit != nil {
            var suitCards = filter(by: suit!)
            suitCards.sortHandOrder()
            for card in suitCards {
                s.append(card.rank.shortDescription)
            }
            suit = suit!.nextLower
            if suit != nil { s.append(".") }
        }
        return s as String
    }

    
    public mutating func sortBySuit() {
        sort(by: { $0.suit < $1.suit || ($0.suit == $1.suit) && $0.rank < $1.rank} )
    }
    
    public mutating func sortHandOrder() {
        sortBySuit()
        reverse()
    }
    
    public func sortedBySuit() -> [Card] {
        var newArray = self
        newArray.sortBySuit()
        return newArray
    }
    
    public func sortedHandOrder() -> [Card] {
        var newArray = self
        newArray.sortHandOrder()
        return newArray
    }
 
    public func filter(by _suit: Suit) -> [Card] {
        return filter { $0.suit == _suit }
    }
    
   // public var highCardPoints: Int {
   //     return reduce(0) { $0 + $1.highCardPoints }
   // }
    
    public func validate(allowDuplicates: Bool = false, requireFullHand: Bool = false) throws -> Void {
        if requireFullHand && self.count != 13 {
            throw CardArrayError.notFullHand(cardInHand: self.count)
        }
        if allowDuplicates == false {
            var seenCards = Set<Card>()
            for card in self {
                if seenCards.insert(card).inserted == false {
                    throw CardArrayError.duplicateCard(card)
                }
            }
        }
    }

    public mutating func removeFirst(_ card: Card) -> Card? {
        if let i = firstIndex(of: card) {
            return remove(at: i)
        }
        return nil
    }
}


