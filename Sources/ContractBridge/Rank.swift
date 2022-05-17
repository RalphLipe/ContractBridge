//
//  Rank.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum Rank: Int, CaseIterable, Comparable {
    case two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    
    public init?(from rankText: String) {
        switch(rankText.lowercased()) {
        case "2", "two": self = .two
        case "3", "three": self = .three
        case "4", "four": self = .four
        case "5", "five": self = .five
        case "6", "six": self = .six
        case "7", "seven": self = .seven
        case "8", "eight": self = .eight
        case "9", "nine": self = .nine
        case "t", "10", "ten" : self = .ten
        case "j", "jack": self = .jack
        case "q", "queen": self = .queen
        case "k", "king": self = .king
        case "a", "ace": self = .ace
        default: return nil
        }
    }
    
    public var highCardPoints: Int {
        switch self {
        case .ace:   return 4
        case .king:  return 3
        case .queen: return 2
        case .jack:  return 1
        default:     return 0
        }
    }
    
    public var nextLower: Rank? {
        return self == .two ? nil : Rank(rawValue: self.rawValue - 1)
    }
    
    public var nextHigher: Rank? {
        return self == .ace ? nil : Rank(rawValue: self.rawValue + 1)
    }
    
    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var shortDescription: String {
        switch self {
        case .two:   return "2"
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "T"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        }
    }
}

extension Rank: Strideable {
    public func advanced(by n: Int) -> Rank {
        return Rank(rawValue: self.rawValue + n)!
    }

    public func distance(to other: Rank) -> Int {
        return other.rawValue - self.rawValue
    }
}
