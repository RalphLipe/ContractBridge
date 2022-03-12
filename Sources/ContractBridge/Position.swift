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
        return Position(rawValue: (self.rawValue + 1) % 4)!
    }
    
    public var partner: Position {
        return Position(rawValue: (self.rawValue + 2) % 4)!
    }
    
    public var pairPosition: PairPosition {
        switch self {
        case .north, .south: return .ns
        case .east, .west:   return .ew
        }
    }
    
    public var shortDescription: String {
        switch (self) {
        case .north: return "N"
        case .east:  return "E"
        case .south: return "S"
        case .west:  return "W"
        }
    }
}
