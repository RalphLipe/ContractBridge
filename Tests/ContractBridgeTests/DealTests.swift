//
//  DealTests.swift
//  
//
//  Created by Ralph Lipe on 3/23/22.
//

import XCTest
import ContractBridge

class DealTests: XCTestCase {

    func testInit() throws {
        let deal = try! Deal(from: "N:AKQ.432.432.AKQJ - 234... -")
        XCTAssertEqual(deal[.north].count, 13)
        XCTAssertEqual(deal[.east].count, 0)
        XCTAssertEqual(deal[.south].count, 3)
        
        
        XCTAssertTrue(deal[.south].contains(Card(.four, .spades)))
    }
    
}
