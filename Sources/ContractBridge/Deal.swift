//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

enum DealError: Error {
    case invalidNumverOfHands(_ numberOfHands: Int)
    case invalidFirstPosition
    case tooManyHands(_ numberOfHands: Int)
    case notFullHand(position: Position, numberOfCards: Int)
    case duplicateCard(_ card: Card)
}

public class Deal: Codable {
  //  private var hands = Array<[Card]>(repeating: [], count: Position.allCases.count)
    private var hands = Array<Set<Card>>(repeating: [], count: Position.allCases.count)
    public init() {}
    
    public subscript(position: Position) -> Set<Card> {
        get { return hands[position.rawValue] }
        set { hands[position.rawValue] = newValue }
    }
    
    required public convenience init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(from: s)
    }

    public convenience init(from: String) throws {
        self.init()
        let c0 = from.startIndex
        let c1 = from.index(c0, offsetBy: 1)
        guard let firstPosition = Position(from: String(from[c0..<c1])) else {
            throw DealError.invalidFirstPosition
        }
        let c2 = from.index(c1, offsetBy: 1)
        if String(from[c1..<c2]) != ":" {
            throw DealError.invalidFirstPosition
        }
        var position = firstPosition
        let serHands = String(from[c2...]).components(separatedBy: .whitespaces)
        if serHands.count > Position.allCases.count {
            throw DealError.tooManyHands(serHands.count)
        }
        for serHand in serHands {
            self[position] = try Set(Array<Card>.fromSerialized(serHand))
            position = position.next
        }
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialize())
    }
    
    public func serialize(startPosition: Position = .north) -> String {
        let s = NSMutableString(capacity: 52+2+(4*3)+3)
        s.append(startPosition.shortDescription)
        s.append(":")
        var position = startPosition
        for _ in Position.allCases {
            s.append(toCardArray(position: position).serialized)
            position = position.next
            if position != startPosition {
                s.append(" ")
            }
        }
        return s as String
    }
    
    // For this method we want to construct a pure array, instead of using the map method.
    // This allows state bindings to use the array.  Map produces slices
    public func toCardArray(position: Position) -> [Card] {
        var cards: [Card] = []
        for card in self[position] {
            cards.append(card)
        }
        cards.sortHandOrder()
        return cards
    }
    
    public func toDictOfArrays() -> [Position: [Card]] {
        var dict: [Position: [Card]] = [:]
        for position in Position.allCases {
            dict[position] = toCardArray(position: position)
        }
        return dict
    }
    
    public func validate(fullDeal: Bool = true) throws -> Void {
        if fullDeal {
            for position in Position.allCases {
                if self[position].count != 13 {
                    throw DealError.notFullHand(position: position, numberOfCards: self[position].count)
                }
            }
        }
        // TODO:  Can be much more efficent.   Maybe doesn't matter
        var seenCards = Set<Card>()
        for hand in self.hands {
            for card in hand {
                if seenCards.insert(card).inserted == false {
                    throw DealError.duplicateCard(card)
                }
            }
        }
    }
}
