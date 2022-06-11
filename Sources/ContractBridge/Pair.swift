//
//  PairPosition.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum Pair: Int, CaseIterable {
    case ns = 0, ew
    public var positions: (Position, Position)  {
        switch self {
        case .ns: return (.north, .south)
        case .ew: return (.east, .west)
        }
    }
    public var opponents: Pair {
        return self == .ns ? .ew : .ns
    }
}
 
public extension String.StringInterpolation {
    mutating func appendInterpolation(_ pair: Pair, style: ContractBridge.Style = .symbol) {
        let positions = pair.positions
        appendLiteral("\(positions.0, style: style)/\(positions.1, style: style)")
    }
}
