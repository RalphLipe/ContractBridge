//
//  PairPosition.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum PairPosition {
    case ns, ew
    public var positions: (Position, Position)  {
        switch self {
        case .ns: return (.north, .south)
        case .ew: return (.east, .west)
        }
    }
    public var opponents: PairPosition {
        return self == .ns ? .ew : .ns
    }
    public var shortDescription: String {
        switch self {
        case .ns: return "N/S"
        case .ew:   return "E/W"
        }
    }
}
 
