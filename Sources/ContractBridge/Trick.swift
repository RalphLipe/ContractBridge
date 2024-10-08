//
//  Trick.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum TrickError: Error {
    case mustFollowSuit(leadSuit: Suit)
    case playOutOfTurn(nextToAct: Direction)
    case trickComplete
    case cantUndoLead
}

public struct Trick {
    public let leadPosition: Direction
    public let strain: Strain
    
    private(set) public var cards: Dictionary<Direction, Card>
    private(set) public var nextToAct: Direction
    private(set) public var winningPosition: Direction
    
    public var isComplete: Bool { cards.count == Direction.allCases.count }
    public var leadSuit: Suit { cards[leadPosition]!.suit }
    public var winningCard: Card { cards[winningPosition]! }
    public var isTrumped: Bool { return leadSuit != strain.suit && winningCard.suit == strain.suit }
    
    public init(lead: Card, position: Direction, strain: Strain) {
        self.cards = [position: lead]
        self.leadPosition = position
        self.winningPosition = position
        self.nextToAct = position.next
        self.strain = strain
    }
    
    public mutating func play(card: Card, position: Direction, remainingHand: Set<Card>? = nil) throws {
        if isComplete {
            throw TrickError.trickComplete
        }
        if position != nextToAct {
            throw TrickError.playOutOfTurn(nextToAct: nextToAct)
        }
        if remainingHand != nil && card.suit != leadSuit && 
            remainingHand!.contains(where: { $0.suit == leadSuit }) {
            throw TrickError.mustFollowSuit(leadSuit: leadSuit)
        }
        assert(cards[position] == nil)
        if wouldWin(card) { winningPosition = position }
        cards[position] = card
        nextToAct = isComplete ? winningPosition : nextToAct.next
    }
    
    private mutating func rollBackToLead() {
        if cards.count == 1 {
            winningPosition = leadPosition
        } else {
            let position = nextToAct.previous
            let card = cards.removeValue(forKey: position)!
            nextToAct = position
            rollBackToLead()
            try! play(card: card, position: position)
        }
    }
    
    public mutating func undoPlay() throws -> Card {
        if cards.count == 1 {
            throw TrickError.cantUndoLead
        }
        // IMPORTANT!  When the trick is complete, nextToAct becomes the winner of the
        // trick. If the trick is complete then use the lead position's previous to undo
        let position = isComplete ? leadPosition.previous : nextToAct.previous
        let card = cards.removeValue(forKey: position)!
        nextToAct = position
        // If the last card was the winner then we have to figure out the winning card all over again.
        // The best way to do this is to undo all the plays up to the lead and then redo them
        if winningPosition == position {
            rollBackToLead()
        }
        return card
    }
    
    public func wouldWin(_ card: Card) -> Bool {
        if isTrumped {
            return card.suit == strain.suit && card.rank > winningCard.rank
        } else {
            return card.suit == strain.suit || (card.suit == leadSuit && card.rank > winningCard.rank)
        }
    }
    
    private func cheapestWinner(_ suitCards: Set<Card>) -> Card? {
        var winner: Card? = nil
        for card in suitCards {
            if card > winningCard && (winner == nil || card < winner!) { winner = card }
        }
        return winner
    }
    
    private func cheapestCard(_ cards: Set<Card>) -> Card? {
        var cheapest: Card? = nil
        for card in cards {
            if cheapest == nil || card.rank < cheapest!.rank { cheapest = card }
        }
        return cheapest
    }
    
    public func winningCard(hand: Set<Card>) -> Card? {
        let suitCards = hand.filter { $0.suit == leadSuit }
        if suitCards.count > 0 {
            return isTrumped ? nil : cheapestWinner(suitCards)
        } else {
            if strain == .noTrump {
                return nil
            }
            let trumps = hand.filter { $0.suit == strain.suit! }
            return isTrumped ? cheapestWinner(trumps) : cheapestCard(trumps)
        }
    }
    
    public func legalCard(hand: Set<Card>) -> Card? {
        let suitCards = hand.filter { $0.suit == leadSuit }
        return suitCards.count > 0 ? cheapestCard(suitCards) : cheapestCard(hand)
    }
    
    public func winIfPossible(hand: Set<Card>) -> Card? {
        let winningCard = winningCard(hand: hand)
        return winningCard == nil ? legalCard(hand: hand) : winningCard
    }
}
