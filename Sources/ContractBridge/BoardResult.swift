//
//  File.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/25/24.
//

import Foundation

public class BoardResult : Codable {
    public let boardNumber: Int
    public let nsPairNumber: Int
    public let ewPairNumber: Int
    public let contract: Contract
    public let declarer: Direction
    public let score: Int
    public init(boardNumber: Int, nsPairNumber: Int, ewPairNumber: Int, contract: Contract, declarer: Direction, score: Int)
    {
        self.boardNumber = boardNumber
        self.nsPairNumber = nsPairNumber
        self.ewPairNumber = ewPairNumber
        self.contract = contract
        self.declarer = declarer
        self.score = score
    }
}
