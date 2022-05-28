//
//  CardSetTests.swift
//  
//
//  Created by Ralph Lipe on 5/27/22.
//

import XCTest
import ContractBridge

class CardSetTests: XCTestCase {

    func testHighCardPoints() throws {
        let cards: Set<Card> = [.kingOfClubs, .queenOfHearts, .fiveOfSpades]
        XCTAssertEqual(cards.highCardPoints, 5)
    }


}
