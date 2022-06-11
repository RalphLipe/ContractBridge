//
//  Rank.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum Rank: Int, CaseIterable, Comparable, Strideable {
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
        return Rank(rawValue: rawValue - 1)
    }
    
    public var nextHigher: Rank? {
        return Rank(rawValue: rawValue + 1)
    }
    
    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public func advanced(by n: Int) -> Rank {
        return Rank(rawValue: self.rawValue + n)!
    }

    public func distance(to other: Rank) -> Int {
        return other.rawValue - self.rawValue
    }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ rank: Rank, style: ContractBridge.Style = .symbol) {
        
        var s: String
        switch style {
        case .symbol, .character:
            switch rank {
            case .two:   s = "2"
            case .three: s = "3"
            case .four:  s = "4"
            case .five:  s = "5"
            case .six:   s = "6"
            case .seven: s = "7"
            case .eight: s = "8"
            case .nine:  s = "9"
            case .ten:   s = "T"
            case .jack:  s = "J"
            case .queen: s = "Q"
            case .king:  s = "K"
            case .ace:   s = "A"
            }
        case .name:
            switch rank {
            case .two:   s = "two"
            case .three: s = "three"
            case .four:  s = "four"
            case .five:  s = "five"
            case .six:   s = "six"
            case .seven: s = "seven"
            case .eight: s = "eight"
            case .nine:  s = "nine"
            case .ten:   s = "ten"
            case .jack:  s = "jack"
            case .queen: s = "queen"
            case .king:  s = "king"
            case .ace:   s = "ace"
            }
        }
        appendLiteral(s)
    }
}

