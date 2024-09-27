//
//  Pair.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/26/24.
//

import Foundation

public struct Pair: Codable {
    public let number: Int
    public let pairDirection: PairDirection
    public let player0: String
    public let player1: String
}
