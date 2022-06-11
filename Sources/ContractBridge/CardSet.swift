//
//  CardSet.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation

public enum CardSetError: Error {
    case tooManySuits(_ count: Int)
}


public extension Set where Element == Card {
    init(from: String) throws  {
        self.init()
        let rankStrings = from.components(separatedBy: ".")
        if rankStrings.count > Suit.allCases.count {
            throw CardSetError.tooManySuits(rankStrings.count)
        }
        let rankSets = try rankStrings.map { try Set<Rank>(from: $0) }
        let suits: [Suit] = Suit.allCases.reversed()
        for i in rankSets.indices {
            for rank in rankSets[i] {
                insert(Card(rank, suits[i]))
            }
        }
    }
    
    func sortedHandOrder(suit: Suit? = nil) -> [Card] {
        if let suit = suit {
            return self.filter { $0.suit == suit }.sortedHandOrder()
        } else {
            return Array(self).sortedHandOrder()
        }
    }

    var highCardPoints: Int {
        return reduce(0) { $0 + $1.rank.highCardPoints }
    }

    func ranks(for suit: Suit) -> Set<Rank> {
        var ranks = Set<Rank>()
        self.forEach { if $0.suit == suit { ranks.insert($0.rank) } }
        return ranks
    }
    
    var serialized: String {
        return Suit.allCases.reversed().map { ranks(for: $0).serialized }.joined(separator: ".")
    }
    
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ cards: Set<Card>, style: ContractBridge.Style = .symbol) {
        var s = ""
        for suit in Suit.allCases.reversed() {
            s += "\(suit, style: style)"
            if style != .symbol { s += ": " }
            let ranks = cards.ranks(for: suit)
            if ranks.count == 0 {
                s += "-"
            } else {
                s += "\(ranks, style: style)"
            }
            if suit != .clubs { s += " " }
        }
        appendLiteral(s)
    }
}
