//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

enum DealSyntaxError: Error {
    case invalidNumverOfHands(_ numberOfHands: Int)
    case invalidFirstPosition
    case tooManyHands(_ numberOfHands: Int)

}

public struct Deal: Codable {
    private var hands = Array<CardCollection>(repeating: CardCollection(), count: Position.allCases.count)
    
    public init() {}
    
    public subscript(position: Position) -> CardCollection {
        get {
            return hands[position.rawValue]
        }
        set {
            hands[position.rawValue] = newValue
        }
    }
    
    public init(from: Decoder) throws {
        let decoder = try from.singleValueContainer()
        let s = try decoder.decode(String.self)
        try self.init(from: s)
    }

    public init(from: String) throws {
        self.init()
        let c0 = from.startIndex
        let c1 = from.index(c0, offsetBy: 1)
        guard let firstPosition = Position(from: String(from[c0..<c1])) else {
            throw DealSyntaxError.invalidFirstPosition
        }
        let c2 = from.index(c1, offsetBy: 1)
        if String(from[c1..<c2]) != ":" {
            throw DealSyntaxError.invalidFirstPosition
        }
        var position = firstPosition
        let serHands = String(from[c2...]).components(separatedBy: .whitespaces)
        if serHands.count > Position.allCases.count {
            throw DealSyntaxError.tooManyHands(serHands.count)
        }
        for serHand in serHands {
            try self[position] = CardCollection(from: serHand)
            position = position.next
        }
    }
    
    public func encode(to: Encoder) throws {
        var encoder = to.singleValueContainer()
        try encoder.encode(self.serialized)
    }
    
    public var serialized: String {
        var s = "N:"
        for position in Position.allCases {
            s += self[position].serialized
            if position != .west {
                s += " "
            }
        }
        return s
    }
}
