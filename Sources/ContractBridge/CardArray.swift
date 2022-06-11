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
    
    public mutating func removeFirst(_ card: Card) -> Card? {
        if let i = firstIndex(of: card) {
            return remove(at: i)
        }
        return nil
    }
}


