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
}
