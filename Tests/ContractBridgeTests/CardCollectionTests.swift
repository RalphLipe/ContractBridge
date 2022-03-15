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
        
        XCTAssertEqual(CardCollection(numberOfDecks: 1).count, 52)
        let fourDecks = CardCollection(numberOfDecks: 4)
        XCTAssertEqual(fourDecks.count, 52*4)
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
    
    func testSortHandOrder() throws {
        var cc: CardCollection = [Card(.two, .clubs), Card(.three, .clubs), Card(.ace, .spades)]
        cc.sortHandOrder()
        XCTAssertEqual(cc[0], Card(.ace, .spades))
        XCTAssertEqual(cc[2], Card(.two, .clubs))
    }
    
    func testSerialized() throws {
        var cc = CardCollection()
        XCTAssertEqual(cc.serialized, "-")
        cc.append(Card(.two, .diamonds))
        XCTAssertEqual(cc.serialized, "..2.")
        cc.append(Card(.jack, .hearts))
        XCTAssertEqual(cc.serialized, ".J.2.")
        cc.append(Card(.queen, .hearts))
        XCTAssertEqual(cc.serialized, ".QJ.2.")
        cc.append(Card(.two, .clubs))
        XCTAssertEqual(cc.serialized, ".QJ.2.2")
        cc.append(Card(.ten, .spades))
        XCTAssertEqual(cc.serialized, "T.QJ.2.2")
        cc.shuffle()
        XCTAssertEqual(cc.serialized, "T.QJ.2.2")
        
        
        cc = CardCollection(numberOfDecks: 1)
        XCTAssertEqual(cc.serialized, "AKQJT98765432.AKQJT98765432.AKQJT98765432.AKQJT98765432")
        cc.shuffle()
        XCTAssertEqual(cc.serialized, "AKQJT98765432.AKQJT98765432.AKQJT98765432.AKQJT98765432")
    }
    
    
    func testPoints() throws {
        XCTAssertEqual(try CardCollection(from: "akq.akq.akq.akqj").points, 37)
        XCTAssertEqual(CardCollection().points, 0)
    }
    
    func testSuitCards() throws {
        let hand = try CardCollection(from: "ajt7.432.kq.at52")
        XCTAssert(hand.suitCards(.diamonds).contains(Card(.king, .diamonds)))
        XCTAssertEqual(hand.suitCards(.clubs).count, 4)
        XCTAssertEqual(hand.suitCards(.hearts).serialized, ".432..")
    }

    func testRemoveFirst() throws {
        var hand = try CardCollection(from: "ajt7.432.kq.at52")
        XCTAssertEqual(hand.removeFirst(Card(.ace, .clubs)), Card(.ace, .clubs))
        XCTAssertNil(hand.removeFirst(Card(.ace, .clubs)))
        
        hand = try CardCollection(from: "QKJJJ", allowDuplicates: true)
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertNil(hand.removeFirst(Card(.jack, .spades)))
    }
    
    func testRemoveCard() throws {
        var cc = try CardCollection(from: "AKQ.234")
        let removed = cc.removeFirst(Card(.king, .spades))
        XCTAssertEqual(removed, Card(.king, .spades))
        let removeSameCard = cc.removeFirst(Card(.king, .spades))
        XCTAssertNil(removeSameCard)
        _ = cc.removeFirst(Card(.three, .hearts))
        XCTAssertEqual(cc.serialized, "AQ.42..")
        
        cc = CardCollection(Array<Card>(repeating: Card(.four, .diamonds), count: 5))
        cc.append(Card(.ace, .spades))
        XCTAssertEqual(cc.serialized, "A..44444.")
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc.serialized, "A..4444.")
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc.serialized, "A..444.")
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
            XCTFail("Unexpected error: \(error)")
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
        
        XCTAssertNoThrow(try CardCollection(from: "aaakkkqqq", allowDuplicates: true))
        XCTAssertThrowsError(try CardCollection(from: "aakqj"))
    }
}
