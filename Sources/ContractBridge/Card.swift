//
//  Card.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


struct Card : Comparable, Hashable {
    let suit: Suit
    let rank: Rank
    
    init(_ rank: Rank, _ suit: Suit) {
        self.suit = suit
        self.rank = rank
    }
    
    init?(suit: Suit, rankText: String) {
        if let rank = Rank(rankText) {
            self.init(rank, suit)
        } else {
            return nil
        }
    }
    
    var shortDescription: String {
        return "\(rank.shortDescription)\(suit.shortDescription)"
    }
    
    var points: Int {
        switch self.rank {
        case .ace:   return 4
        case .king:  return 3
        case .queen: return 2
        case .jack:  return 1
        default:     return 0
        }
    }
    
    //  BUGUBUG -- is this the right place to have this
    static func newDeck() -> [Card] {
        var deck = Array<Card>()
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank, suit))
            }
        }
        return deck
    }
    
    static func < (lhs: Card, rhs: Card) -> Bool {
        if (lhs.suit == rhs.suit) {
            return lhs.rank < rhs.rank
        } else {
            return lhs.suit < rhs.suit
        }
    }
}

extension Card: CustomStringConvertible {
    var description: String {
        return "\(rank) of \(suit)"
    }
}

