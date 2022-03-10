//
//  Strain.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation
import SwiftUI  // TODO: Move to ContractBridgeUI

public enum Strain: Int, Comparable, CaseIterable {
    case clubs = 0, diamonds, hearts, spades, noTrump
    public static func < (lhs: Strain, rhs: Strain) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    var shortDescription : String {
        switch self {
        case .noTrump: return "NT"
        default: return Suit(rawValue: self.rawValue)!.shortDescription
        }
    }
    var color: SwiftUI.Color {
        switch self {
        case .noTrump: return .black
        default:       return Suit(rawValue: self.rawValue)!.color
        }
    }
    var trickScore: Int {
        switch self {
        case .noTrump, .spades, .hearts:  return 30
        case .clubs, .diamonds:           return 20
        }
    }
    var firstTrickScore: Int {
        return (self == .noTrump) ? 40 : trickScore
    }
}
