//
//  Position.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Position: Int, CaseIterable {
    case north = 0, east, south, west
    public init?(_ positionText: String) {
        switch (positionText.lowercased()) {
        case "n", "north": self = .north
        case "e", "east": self = .east
        case "s", "south": self = .south
        case "w", "west": self = .west
        default: return nil
        }
    }
    public static func + (left: Position, right: Int) -> Position {
        return Position(rawValue: (left.rawValue + right) % 4)!
    }
    public var next: Position {
        return self + 1
    }
    public var partner: Position {
        return self + 2
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
        case .west: return "W"
        }
    }
}
