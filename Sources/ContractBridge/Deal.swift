//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public typealias Hands = Dictionary<Position, Set<Card>>

enum DealError: Error {
    case invalidFirstPosition
    case invalidNumberOfHands(_ numberOfHands: Int)
    case notFullHand(position: Position, numberOfCards: Int)
    case nilHand(position: Position)
    case duplicateCard(_ card: Card)
}


public struct Deal: Codable {
    public var hands: Hands = [:]
    
    public init() {}
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(from: s)
    }

    public init(from: String) throws {
        if from.count < 2 { throw DealError.invalidFirstPosition }
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
        if serHands.count != Position.allCases.count {
            throw DealError.invalidNumberOfHands(serHands.count)
        }
        for serHand in serHands {
            hands[position] = serHand == "-" ? nil : try Set<Card>(from: serHand)
            position = position.next
        }
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialize())
    }
    
    public func serialize(startPosition: Position = .north) -> String {
        var serHands = Array<String>()
        var position = startPosition
        repeat {
            serHands.append(hands[position] == nil ? "-" : hands[position]!.serialized)
            position = position.next
        } while position != startPosition
        return "\(startPosition, style: .character):" + serHands.joined(separator: " ")
    }
    
    public func validate(fullDeal: Bool = true) throws -> Void {
        if fullDeal {
            for position in Position.allCases {
                guard let hand = hands[position] else { throw DealError.nilHand(position: position) }
                if hand.count != 13 {
                    throw DealError.notFullHand(position: position, numberOfCards: hand.count)
                }
            }
        }
        var seenCards = Set<Card>()
        for hand in self.hands.values {
            let dup = seenCards.intersection(hand)
            if dup.count > 0 {
                throw DealError.duplicateCard(dup.first!)
            }
            seenCards.formUnion(hand)
        }
    }
}
