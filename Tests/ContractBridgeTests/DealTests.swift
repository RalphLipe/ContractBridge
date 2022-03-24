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
        
        // Hands should be sorted in hand order
        XCTAssertEqual(deal[.south][0], Card(.four, .spades))
    }

    func testSortHandOrder() throws {
        var deal = Deal()
        deal[.north] = [Card(.two, .clubs), Card(.three, .diamonds), Card(.four, .spades), Card(.ace, .spades)]
        deal[.west] = [Card(.king, .hearts), Card(.ace, .hearts)]
        XCTAssertEqual(deal[.north][0].rank, .two)
        XCTAssertEqual(deal[.west][1].rank, .ace)
        deal.sortHandOrder()
        XCTAssertEqual(deal[.north][0].rank, .ace)
        XCTAssertEqual(deal[.west][1], Card(.king, .hearts))
    }
    
}
