//
//  CardSetTests.swift
//  
//
//  Created by Ralph Lipe on 5/27/22.
//

import XCTest
import ContractBridge

class CardSetTests: XCTestCase {

    func testInit() throws {
        let fromLiteral: Set<Card> = [.aceOfDiamonds, .jackOfClubs]
        
        let randomCard = fromLiteral.randomElement()!
        XCTAssertTrue(fromLiteral.contains(randomCard))
        
        XCTAssertThrowsError(try Set<Card>(from: "Bogus string"))
        XCTAssertNoThrow(try Set<Card>(from:"akq.akq.akq.akqj"))
        XCTAssertThrowsError(try Set<Card>(from: "akq.aqa.akq.2345"))    // Double ace of hearts
        XCTAssertThrowsError(try Set<Card>(from: "akq.234.akq.2345."))   // Extra "."
        
        XCTAssertEqual(try Set<Card>(from: "").count, 0)           // Blank string is valid, no cards
        XCTAssertEqual(try Set<Card>(from: "7").first, .sevenOfSpades)
        XCTAssertEqual(try Set<Card>(from: "..4.").first, .fourOfDiamonds)
        
    }
    
    func testHighCardPoints() throws {
        let cards: Set<Card> = [.kingOfClubs, .queenOfHearts, .fiveOfSpades]
        XCTAssertEqual(cards.highCardPoints, 5)
    }
    
    func testSortedHandOrder() throws {
        let cards: Set<Card> = [.aceOfSpades, .twoOfSpades, .queenOfClubs, .queenOfHearts, .queenOfDiamonds, .jackOfSpades, .queenOfSpades, .fiveOfClubs]
        XCTAssertEqual(cards.sortedHandOrder(), [.aceOfSpades, .queenOfSpades, .jackOfSpades, .twoOfSpades, .queenOfHearts, .queenOfDiamonds, .queenOfClubs, .fiveOfClubs])
        XCTAssertEqual(cards.sortedHandOrder(suit: .clubs), [.queenOfClubs, .fiveOfClubs])
    }

    
    func testSerialized() throws {
        var cardSet = Set<Card>()
        XCTAssertEqual(cardSet.serialized, "...")
        cardSet.insert(.twoOfDiamonds)
        XCTAssertEqual(cardSet.serialized, "..2.")
        cardSet.insert(.jackOfHearts)
        XCTAssertEqual(cardSet.serialized, ".J.2.")
        cardSet.insert(Card(.queen, .hearts))
        XCTAssertEqual(cardSet.serialized, ".QJ.2.")
        cardSet.insert(Card(.two, .clubs))
        XCTAssertEqual(cardSet.serialized, ".QJ.2.2")
        cardSet.insert(Card(.ten, .spades))
        XCTAssertEqual(cardSet.serialized, "T.QJ.2.2")
    }

}
