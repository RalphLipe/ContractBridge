//
//  CardTest.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class CardTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCard() throws {
        XCTAssertLessThan(Card(.ten, .spades), Card(.jack, .spades))
        XCTAssertEqual(Card(.jack, .diamonds).description, "jack of diamonds")
        XCTAssertEqual(Card(.queen, .clubs).points, 2)
    }
}
