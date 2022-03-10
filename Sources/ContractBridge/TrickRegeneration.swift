//
//  TrickRegeneration.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public class TrickRegeneration {
    var allInOrder = true
    var lastCardFrom: Position? = nil
    var firstCardFrom: Position? = nil
    var reconstructedDeal: Deal = Deal()
    private var cardPositions: [Card: Position] = [:]
    private var insertPos: Int? = nil
    
    init(previousDeal: Deal) {
        // Initialize sets here
        for position in Position.allCases {
            for card in previousDeal[position] {
                cardPositions[card] = position
            }
        }
    }
    func cardDealt(_ card: Card) {
        if allInOrder {
            guard let position = cardPositions[card]  else {
                // TODO Something odd here...
                allInOrder = false
                return
            }
            if position == lastCardFrom {
                if insertPos == nil {
                    reconstructedDeal[position].append(card)
                } else {
                    reconstructedDeal[position].insert(card, at: insertPos!)
                    insertPos! += 1
                }
            } else {
                if lastCardFrom == nil {
                    lastCardFrom = position
                    firstCardFrom = position
                    reconstructedDeal[position].append(card)
                } else {
                    // The hand has changed from one position to another.  If it's the first hand then there
                    // may be less than 13 cards.
                    if lastCardFrom != firstCardFrom && reconstructedDeal[lastCardFrom!].count != 13 {
                        allInOrder = false
                        return
                    }
                    // Have we "wrapped around" a suit.  If so, set insertPos to 0 to start inserting at the
                    // front of the list.
                    if position == firstCardFrom {
                        reconstructedDeal[position].insert(card, at: 0)
                        insertPos! = 1
                    } else {
                        reconstructedDeal[position].append(card)
                    }
                    lastCardFrom = position
                }
            }
        }
        
    }
}

