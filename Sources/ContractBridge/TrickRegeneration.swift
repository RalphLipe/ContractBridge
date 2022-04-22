//
//  TrickRegeneration.swift
//
//  This specialized class can be used to attempt to reconstruct card play from a deck of cards given
//  the previous deal and contract.  If players keep tricks played in order and cut the deck at most one
//  time then this code can determinw each card played in a sequence of tricks.  This can be useful
//  to reconstruct the play of a hand while dealing out a new set of hands.
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation
/*  TODO:  Make this work with deal using sets of cards instead of arrays.  May need to make
 our own internal data structure...
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
                    reconstructedDeal[position].insert(card)
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
*/
