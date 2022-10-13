//
//  PositionRanks.swift
//  
//
//  Created by Ralph Lipe on 9/22/22.
//

import Foundation

public struct PositionRanks: Equatable {
    private var ranks: [Rank?] = Array<Rank?>(repeating: nil, count: Position.allCases.count)

    public init() { }
    
    public subscript(position: Position) -> Rank? {
        get {
            return ranks[position.rawValue]
        }
        set {
            ranks[position.rawValue] = newValue
        }
    }
    
    public var winning: (position: Position, rank: Rank)? {
        var winPos: Position? = nil
        var winRank = Rank.two
        for position in Position.allCases {
            if let rank = self[position] {
                if rank >= winRank {    // IMPORTANT:  Check for >= so even a .two will assign a winner
                    winRank = rank
                    winPos = position
                }
            }
        }
        if let winner = winPos {
            return (position: winner, rank: winRank)
        } else {
            return nil
        }
    }
    
    public var count: Int {
        return ranks.reduce(0) { return $1 == nil ? $0 : $0 + 1 }
    }
    
    public var isEmpty: Bool {
        return ranks.allSatisfy { $0 == nil }
    }
    
}


public extension String.StringInterpolation {
    mutating func appendInterpolation(_ positionRanks: PositionRanks, style: ContractBridge.Style = .symbol) {
        for position in Position.allCases {
            var rankString = "-"
            if let rank = positionRanks[position] {
                rankString = "\(rank)"
            }
            appendLiteral("\(position):\(rankString) ")
        }
        if let winning = positionRanks.winning {
            appendLiteral(" \(winning.position) won with \(winning.rank)")
        }
    }
}
