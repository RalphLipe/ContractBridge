//
//  Strain.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public enum Strain: Int, Comparable, CaseIterable {
    case clubs = 0, diamonds, hearts, spades, noTrump
    public static func < (lhs: Strain, rhs: Strain) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    public var shortDescription : String {
        switch self {
        case .noTrump: return "NT"
        default: return Suit(rawValue: self.rawValue)!.shortDescription
        }
    }

    public var trickScore: Int {
        switch self {
        case .noTrump, .spades, .hearts:  return 30
        case .clubs, .diamonds:           return 20
        }
    }
    public var firstTrickScore: Int {
        return (self == .noTrump) ? 40 : trickScore
    }
}
