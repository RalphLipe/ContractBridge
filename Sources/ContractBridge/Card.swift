//
//  Card.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public struct Card : Comparable, Hashable, CustomStringConvertible {
    public let rank: Rank
    public let suit: Suit

    /*
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
*/
    public init(_ rank: Rank, _ suit: Suit) {
        self.rank = rank
        self.suit = suit
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

