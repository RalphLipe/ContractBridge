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
    public let leadPosition: Position
    public let strain: Strain
    
    private(set) public var cards: Dictionary<Position, Card>
    private(set) public var nextToAct: Position
    private(set) public var winningPosition: Position
    
    public var isComplete: Bool { cards.count == Position.allCases.count }
    public var leadSuit: Suit { cards[leadPosition]!.suit }
    public var winningCard: Card { cards[winningPosition]! }
    public var isTrumped: Bool { return leadSuit != strain.suit && winningCard.suit == strain.suit }
    
    public init(lead: Card, position: Position, strain: Strain) {
        self.cards = [position: lead]
        self.leadPosition = position
        self.winningPosition = position
        self.nextToAct = position.next
        self.strain = strain
    }
    
    public mutating func play(card: Card, position: Position, remainingHand: CardCollection) throws {
        if isComplete {
            throw TrickError.trickComplete
        }
        if position != nextToAct {
            throw TrickError.playOutOfTurn(nextToAct: nextToAct)
        }
        if card.suit != leadSuit &&
            remainingHand.contains(where: { $0.suit == leadSuit }) {
            throw TrickError.mustFollowSuit(leadSuit: leadSuit)
        }
        assert(cards[position] == nil)
        cards[position] = card
        let trumpSuit = strain.suit
        if (card.suit == winningCard.suit && card.rank > winningCard.rank) ||
            (card.suit == trumpSuit && winningCard.suit != trumpSuit)  {
            winningPosition = position
        }
        nextToAct = isComplete ? winningPosition : nextToAct.next
    }
    
    
    private func cheapestWinner(_ suitCards: CardCollection) -> Card? {
        var winner: Card? = nil
        for card in suitCards {
            if card > winningCard && (winner == nil || card < winner!) { winner = card }
        }
        return winner
    }
    
    private func cheapestCard(_ cards: CardCollection) -> Card? {
        var cheapest: Card? = nil
        for card in cards {
            if cheapest == nil || card.rank < cheapest!.rank { cheapest = card }
        }
        return cheapest
    }
    
    public func winningCard(hand: CardCollection) -> Card? {
        let suitCards = hand.suitCards(leadSuit)
        if suitCards.count > 0 {
            return isTrumped ? nil : cheapestWinner(suitCards)
        } else {
            if strain == .noTrump {
                return nil
            }
            let trumps = hand.suitCards(strain.suit!)
            return isTrumped ? cheapestWinner(trumps) : cheapestCard(trumps)
        }
    }
    
    public func legalCard(hand: CardCollection) -> Card? {
        let suitCards = hand.suitCards(leadSuit)
        return suitCards.count > 0 ? cheapestCard(suitCards) : cheapestCard(hand)
    }
    
    public func winIfPossible(hand: CardCollection) -> Card? {
        let winningCard = winningCard(hand: hand)
        return winningCard == nil ? legalCard(hand: hand) : winningCard
    }
}
