//
//  Card.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public enum Card : Int, Comparable, CaseIterable, Hashable {
    case twoOfClubs = 0, twoOfDiamonds,    twoOfHearts,  twoOfSpades
    case threeOfClubs,   threeOfDiamonds, threeOfHearts, threeOfSpades
    case fourOfClubs,    fourOfDiamonds,  fourOfHearts,  fourOfSpades
    case fiveOfClubs,    fiveOfDiamonds,  fiveOfHearts,  fiveOfSpades
    case sixOfClubs,     sixOfDiamonds,   sixOfHearts,   sixOfSpades
    case sevenOfClubs,   sevenOfDiamonds, sevenOfHearts, sevenOfSpades
    case eightOfClubs,   eightOfDiamonds, eightOfHearts, eightOfSpades
    case nineOfClubs,    nineOfDiamonds,  nineOfHearts,  nineOfSpades
    case tenOfClubs,     tenOfDiamonds,   tenOfHearts,   tenOfSpades
    case jackOfClubs,    jackOfDiamonds,  jackOfHearts,  jackOfSpades
    case queenOfClubs,   queenOfDiamonds, queenOfHearts, queenOfSpades
    case kingOfClubs,    kingOfDiamonds,  kingOfHearts,  kingOfSpades
    case aceOfClubs,     aceOfDiamonds,   aceOfHearts,   aceOfSpades

    public var rank: Rank { Rank(rawValue: self.rawValue / 4)! }
    public var suit: Suit { Suit(rawValue: self.rawValue % 4)! }

    public init(_ rank: Rank, _ suit: Suit) {
        self.init(rawValue: (rank.rawValue * 4) + suit.rawValue)!
    }
    
    
    public static func < (lhs: Card, rhs: Card) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
  
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ card: Card, style: ContractBridge.Style = .symbol) {
        switch style {
        case .symbol, .character:
            appendLiteral("\(card.rank, style: style)\(card.suit, style: style)")
        case .name:
            appendLiteral("\(card.rank, style: style) of \(card.suit, style: style)")
        }
    }
}
