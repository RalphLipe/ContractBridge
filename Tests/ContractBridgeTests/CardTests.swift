//
//  CardTest.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class CardTest: XCTestCase {

    
    func testCard() throws {
        let js = Card.jackOfSpades
        XCTAssertLessThan(Card(.ten, .spades), Card(.jack, .spades))
        XCTAssertEqual("\(js, style: .name)", "jack of spades")
        XCTAssertEqual("\(js, style: .character)", "JS")
        XCTAssertEqual("\(js, style: .symbol)", "J♠")
        XCTAssertEqual(Card.twoOfClubs, Card(.two, .clubs))
    }
}
