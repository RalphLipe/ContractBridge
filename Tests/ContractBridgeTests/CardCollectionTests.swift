//
//  HandTests.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class CardCollectionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        let fromLiteral: CardCollection = [Card(.ace, .diamonds), Card(.jack, .clubs)]
        
        let randomCard = fromLiteral.randomElement()!
        XCTAssertTrue(fromLiteral.contains(randomCard))
        
        XCTAssertThrowsError(try CardCollection(from: "Bogus string"))
        XCTAssertNoThrow(try CardCollection(from: "akq.akq.akq.akqj"))
        XCTAssertThrowsError(try CardCollection(from: "akq.aqa.akq.2345"))    // Double ace of hearts
        XCTAssertThrowsError(try CardCollection(from: "akq.234.akq.2345."))   // Extra "."
        
        XCTAssertEqual(try CardCollection(from: "").count, 0)           // Blank string is valid, no cards
        XCTAssertEqual(try CardCollection(from: "7").first, Card(.seven, .spades))
        XCTAssertEqual(try CardCollection(from: "..4.").first, Card(.four, .diamonds))
    }
    
    func testCodable() throws {
        /// TODO Encode and then decode a hand
        ///
    }
    
    func testPoints() throws {
        XCTAssertEqual(try CardCollection(from: "akq.akq.akq.akqj").points, 37)
        XCTAssertEqual(CardCollection().points, 0)
    }
    
    func testSuitCards() throws {
        let hand = try CardCollection(from: "ajt7.432.kq.at52")
        XCTAssert(hand.suitCards(.diamonds).contains(Card(.king, .diamonds)))
        XCTAssertEqual(hand.suitCards(.clubs).count, 4)
    }

}
