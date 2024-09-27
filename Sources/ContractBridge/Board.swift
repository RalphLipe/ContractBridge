//
//  File.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/24/24.
//

import Foundation

public class Board : Codable {
    public let number: Int;
    public let dealer: Direction;
    public let deal: Deal;
    public let vulnerable: Vulnerable;
    
    public init(number: Int, deal: Deal, dealer: Direction, vulnerable: Vulnerable) {
        self.number = number
        self.dealer = dealer
        self.deal = deal
        self.vulnerable = vulnerable
    }
    
    public init(number: Int, deal: Deal) {
        self.number = number
        self.deal = deal
        self.dealer = Direction.dealer(boardNumber: number)
        self.vulnerable = Vulnerable(boardNumber: number)
    }
}



