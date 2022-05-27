//
//  CardSet.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation

// TODO:  Move this to another file.  RankSet
extension Set where Element == Rank {
    public var description: String {
        var ranks = self.map { $0 }
        ranks.sort()
        ranks.reverse()
        return ranks.reduce("") { $0 + $1.shortDescription }
    }
}

extension Set where Element == Card {
    public var description: String {
        var s = ""
        for suit in Suit.allCases.reversed() {
            s += "\(suit)"
            let ranks = Set<Rank>(self.filter { $0.suit == suit }.map { $0.rank })
            if ranks.count == 0 {
                s += "-"
            } else {
                s += ranks.description
            }
            if suit != .clubs { s += " " }
        }
        return s
    }
    public func ranksFor(_ suit: Suit) -> Set<Rank> {
        var ranks = Set<Rank>()
        self.forEach { if $0.suit == suit { ranks.insert($0.rank) } }
        return ranks
    }
}
