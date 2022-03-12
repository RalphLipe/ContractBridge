//
//  Trick.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum TrickError: Error {
    case mustFollowSuit(leadSuit: Suit)
    case playOutOfTurn(nextToAct: Position)
    case trickComplete
}

public struct Trick {
    let leadPosition: Position
    let strain: Strain
    private var winningIndex: Int
    private(set) public var cards: [Card]
    
    var leadSuit: Suit { cards[0].suit }
    private(set) public var nextToAct: Position
    var trickComplete: Bool { cards.count == Position.allCases.count }

    private(set) public var winningPosition: Position
    var winningCard: Card { cards[winningIndex] }
    
    public init(lead: Card, from: Position, strain: Strain) {
        self.leadPosition = from
        self.nextToAct = from.next
        self.winningPosition = from
        self.cards = [lead]
        self.winningIndex = 0
        self.strain = strain
    }
    
    public mutating func play(card: Card, from: Position, remainingHand: [Card]) throws {
        if trickComplete {
            throw TrickError.trickComplete
        }
        if from != nextToAct {
            throw TrickError.playOutOfTurn(nextToAct: nextToAct)
        }
        if card.suit != leadSuit &&
            remainingHand.contains(where: { $0.suit == leadSuit }) {
            throw TrickError.mustFollowSuit(leadSuit: leadSuit)
        }
        let trumpSuit = strain.suit
        if (card.suit == winningCard.suit && card.rank > winningCard.rank) ||
            (card.suit == trumpSuit && winningCard.suit != trumpSuit)  {
            winningIndex = cards.count
            winningPosition = from
        }
        cards.append(card)
        nextToAct = nextToAct.next
    }
}
