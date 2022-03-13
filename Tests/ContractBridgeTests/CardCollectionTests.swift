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
        let encoder = JSONEncoder()
        let cc = try CardCollection(from: "2345.234.234.qka")
        let data = try encoder.encode(cc)
        let s = String(data: data, encoding: .utf8)!
        XCTAssertEqual(s, "\"5432.432.432.AKQ\"")

        let decoder = JSONDecoder()
        let cc2 = try decoder.decode(CardCollection.self, from: data)
        XCTAssertEqual(cc.serialized, cc2.serialized)
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

    func testValidate() throws {
        let ccDupCard: CardCollection = [Card(.two, .clubs), Card(.ace, .spades), Card(.two, .clubs)]
        var caughtDuplicate = false
        do {
            try ccDupCard.validate()
        } catch CardCollectionError.duplicateCard(let card) {
            caughtDuplicate = true
            XCTAssertEqual(card, Card(.two, .clubs))
        } catch {
            XCTFail("Undepected error: \(error)")
        }
        XCTAssert(caughtDuplicate)
        
        let ccTooShort = try! CardCollection(from: "aj5.t37.2.6")
        do {
            try ccTooShort.validate(requireFullHand: false)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        var caughtPartialHand = false
        do {
            try ccTooShort.validate(requireFullHand: true)
        } catch CardCollectionError.notFullHand(let count) {
            XCTAssertEqual(count, 8)
            caughtPartialHand = true
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssert(caughtPartialHand)
        
        let ccFullValid = try! CardCollection(from: "2345.234.234.234")
        XCTAssertNoThrow(try ccFullValid.validate(requireFullHand: true))
    }
}
