//
//  Position.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Position: Int, CaseIterable {
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

    public var next: Position {
        assert(Position.north.rawValue == 0)
        assert(Position.east.rawValue == 1)
        assert(Position.south.rawValue == 2)
        assert(Position.west.rawValue == 3)
        return Position(rawValue: (self.rawValue + 1) % 4)!
    }

    public var partner: Position {
        return Position(rawValue: (self.rawValue + 2) % 4)!
    }

    public var previous: Position {
        return Position(rawValue: (self.rawValue + 3) % 4)!
    }

    
    public var pair: Pair {
        switch self {
        case .north, .south: return .ns
        case .east, .west:   return .ew
        }
    }
}


public extension String.StringInterpolation {
    mutating func appendInterpolation(_ position: Position, style: ContractBridge.Style = .symbol) {
        var s: String
        switch style {
        case .symbol, .character:
            switch position {
            case .north: s = "N"
            case .east:  s = "E"
            case .south: s = "S"
            case .west:  s = "W"
            }
        case .name:
            switch position {
            case .north: s = "north"
            case .east:  s = "east"
            case .south: s = "south"
            case .west:  s = "west"           
            }
        }
        appendLiteral(s)
    }
}
