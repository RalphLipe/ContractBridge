//
//  Pair.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/26/24.
//

import Foundation

public struct Pair: Codable {
    public let number: Int
    public let direction: PairDirection
    public let player0: String
    public let player1: String
    
    public init(number: Int, direction: PairDirection, player0: String, player1: String) {
        self.number = number
        self.direction = direction
        self.player0 = player0
        self.player1 = player1
    }
    
}
