//
//  Direction.swift
//
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Direction: Int, CaseIterable, Codable {
    case north = 0, east, south, west
    
    public init?(from: String) {
        switch (from.lowercased()) {
        case "n", "north": self = .north
        case "e", "east":  self = .east
        case "s", "south": self = .south
        case "w", "west":  self = .west
        default: return nil
        }
    }

    // TODO: This code is duplicated between Direction and PairDirection and Vulnerable.
    // I hate this but can't figure out a workaround using protocols since Codable provides
    // default implementations that have to be overridden.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let value = Self(from: stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot initialize \(Self.self) from invalid String value \(stringValue)")
        }
        self = value
    }
 
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self, style: .character)")
    }
    // TODO: End of duplicate code
    
    public static func dealer(boardNumber: Int) -> Direction {
        return self.init(rawValue: (boardNumber - 1) % 4)!
    }
    
    public var next: Direction {
        assert(Direction.north.rawValue == 0)
        assert(Direction.east.rawValue == 1)
        assert(Direction.south.rawValue == 2)
        assert(Direction.west.rawValue == 3)
        return Direction(rawValue: (self.rawValue + 1) % 4)!
    }

    public var partner: Direction {
        return Direction(rawValue: (self.rawValue + 2) % 4)!
    }

    public var previous: Direction {
        return Direction(rawValue: (self.rawValue + 3) % 4)!
    }

    
    public var pairDirection: PairDirection {
        switch self {
        case .north, .south: return .ns
        case .east, .west:   return .ew
        }
    }
}


public extension String.StringInterpolation {
    mutating func appendInterpolation(_ direction: Direction, style: ContractBridge.Style = .symbol) {
        var s: String
        switch style {
        case .symbol, .character:
            switch direction {
            case .north: s = "N"
            case .east:  s = "E"
            case .south: s = "S"
            case .west:  s = "W"
            }
        case .name:
            switch direction {
            case .north: s = "north"
            case .east:  s = "east"
            case .south: s = "south"
            case .west:  s = "west"           
            }
        }
        appendLiteral(s)
    }
}
