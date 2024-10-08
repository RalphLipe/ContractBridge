//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

//public typealias Hands = Dictionary<Position, Set<Card>>

public struct Hands {
    private var hands = Array<Set<Card>>(repeating: [], count: Direction.allCases.count)
    
    public init() {}
    
    public subscript(_ position: Direction) -> Set<Card> {
        get { return hands[position.rawValue] }
        set { hands[position.rawValue] = newValue }
    }
}

public enum DealError: Error {
    case invalidFirstPosition
    case cardNotFoundInAnyHand
    case invalidNumberOfHands(_ numberOfHands: Int)
    case notFullHand(position: Direction, numberOfCards: Int)
    case duplicateCard(_ card: Card)
}


public struct Deal: Codable {
    public var hands = Hands()
    
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
        guard let firstPosition = Direction(from: String(from[c0..<c1])) else {
            throw DealError.invalidFirstPosition
        }
        let c2 = from.index(c1, offsetBy: 1)
        if String(from[c1..<c2]) != ":" {
            throw DealError.invalidFirstPosition
        }
        var position = firstPosition
        let serHands = String(from[c2...]).components(separatedBy: .whitespaces)
        if serHands.count != Direction.allCases.count {
            throw DealError.invalidNumberOfHands(serHands.count)
        }
        for serHand in serHands {
            // TODO: What to do with undefined hands?
            // How do we serialize them?
            hands[position] = serHand == "-" ? [] : try Set<Card>(from: serHand)
            position = position.next
        }
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialize())
    }
    
    public func positionFor(card: Card) throws -> Direction {
        for position in Direction.allCases {
            if hands[position].contains(card) {
                return position
            }
        }
        throw DealError.invalidFirstPosition
    }
    
    public func serialize(startPosition: Direction = .north) -> String {
        var serHands = Array<String>()
        var position = startPosition
        repeat {
            serHands.append(hands[position].serialized)
            position = position.next
        } while position != startPosition
        return "\(startPosition, style: .character):" + serHands.joined(separator: " ")
    }
    
    public func validate(fullDeal: Bool = true) throws -> Void {
        if fullDeal {
            for position in Direction.allCases {
                if hands[position].count != 13 {
                    throw DealError.notFullHand(position: position, numberOfCards: hands[position].count)
                }
            }
        }
        var seenCards = Set<Card>()
        for position in Direction.allCases {
            let dup = seenCards.intersection(hands[position])
            if dup.count > 0 {
                throw DealError.duplicateCard(dup.first!)
            }
            seenCards.formUnion(hands[position])
        }
    }
}
