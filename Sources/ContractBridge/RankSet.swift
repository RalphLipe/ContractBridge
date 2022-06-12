//
//  RankSet.swift
//  
//
//  Created by Ralph Lipe on 6/5/22.
//

import Foundation


public enum RankSetError: Error {
    case invalidCharacter(_ character: Character)
    case duplicate(_ rank: Rank)
}


extension Set where Element == Rank  {
    public init(from: String) throws {
        self.init()
        for c in from {
            if let rank = Rank(from: String(c)) {
                if !self.insert(rank).inserted {
                    throw RankSetError.duplicate(rank)
                }
            } else {
                throw RankSetError.invalidCharacter(c)
            }
        }
    }
    
    public var sorted: [Rank] {
        return self.map { $0 }.sorted()
    }
    
    public var sortedHandOrder: [Rank] {
        return self.sorted.reversed()
    }
    
    public var serialized: String {
        return sortedHandOrder.map { "\($0, style: .character)" }.joined()
    }
}


public extension String.StringInterpolation {
    mutating func appendInterpolation(_ ranks: Set<Rank>, style: ContractBridge.Style = .symbol) {
        switch style {
        case .symbol:
            appendLiteral(ranks.serialized)
        case .character, .name:
            appendLiteral(ranks.sortedHandOrder.map { "\($0, style: style)" }.joined(separator: ", "))
        }
    }
}
