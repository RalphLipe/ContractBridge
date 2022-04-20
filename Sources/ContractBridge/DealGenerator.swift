//
//  DealGenerator.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation

public class DealGenerator {
    public static func fillOutEWCards(partialDeal: Deal, suit: Suit) -> Deal {
        // For now as a quick hack this just puts all the cards that are not present
        // in the east hand.
        var newDeal = Deal()
        newDeal[.north] = partialDeal[.north]
        newDeal[.south] = partialDeal[.south]
        newDeal[.west] = []
        let allNS = Set(partialDeal[.north] + partialDeal[.south])
        for rank in Rank.allCases {
            let card = Card(rank, suit)
            if allNS.contains(card) == false {
                newDeal[.east].append(card)
            }
        }
        return newDeal
    }
}
