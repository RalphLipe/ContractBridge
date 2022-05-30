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
    
    func testSortedHandOrder() throws {
        let cards: Set<Card> = [.aceOfSpades, .twoOfSpades, .queenOfClubs, .queenOfHearts, .queenOfDiamonds, .jackOfSpades, .queenOfSpades, .fiveOfClubs]
        XCTAssertEqual(cards.sortedHandOrder(), [.aceOfSpades, .queenOfSpades, .jackOfSpades, .twoOfSpades, .queenOfHearts, .queenOfDiamonds, .queenOfClubs, .fiveOfClubs])
        XCTAssertEqual(cards.sortedHandOrder(suit: .clubs), [.queenOfClubs, .fiveOfClubs])
    }


}
