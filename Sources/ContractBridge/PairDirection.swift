//
//  PairDirection.swift
//
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum PairDirection: Int, CaseIterable, Codable {
    case ns = 0, ew
    public var directions: (Direction, Direction)  {
        switch self {
        case .ns: return (.north, .south)
        case .ew: return (.east, .west)
        }
    }
    public var opponents: PairDirection {
        return self == .ns ? .ew : .ns
    }
}
 
public extension String.StringInterpolation {
    mutating func appendInterpolation(_ pair: PairDirection, style: ContractBridge.Style = .symbol) {
        let directions = pair.directions
        appendLiteral("\(directions.0, style: style)/\(directions.1, style: style)")
    }
}
