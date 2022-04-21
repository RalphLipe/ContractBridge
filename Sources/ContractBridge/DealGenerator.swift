//
//  DealGenerator.swift
//  
//
//  Created by Ralph Lipe on 4/19/22.
//

import Foundation
/*
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
    
    public static func randomDealFromLayout(layout: Int, suit: Suit) -> Deal {
        var deal = Deal()
        var remainingLayout = layout / 4
        var startPosition = Position(rawValue: layout % 4)!
        var cards: [Card] = [Card(.two, suit)]
        var positions: [Position] = [startPosition]
        var rank: Rank? = Rank.three
        while rank != nil {
            let card = Card(rank!, suit)
            let currentPosition = Position(rawValue: remainingLayout % 4)!
            if currentPosition.pairPosition == startPosition.pairPosition {
                cards.append(card)
                positions.append(currentPosition)
            } else {
                cards.shuffle()
                assert(cards.count == positions.count)
                for i in positions.indices {
                    deal[positions[i]].append(cards[i])
                }
                cards = [card]
                positions = [currentPosition]
                startPosition = currentPosition
            }
            rank = rank!.nextHigher
            remainingLayout /= 4
        }
        cards.shuffle()
        assert(cards.count == positions.count)
        for i in positions.indices {
            deal[positions[i]].append(cards[i])
        }
        return deal
    }
}
*/
