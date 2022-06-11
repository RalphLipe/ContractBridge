//
//  CardArrayTests.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class CardArrayTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    

    func testSortHandOrder() throws {
        var cc: [Card] = [.twoOfClubs, .threeOfClubs, .aceOfSpades, .twoOfSpades, .fiveOfHearts, .queenOfHearts, .eightOfHearts]
        cc.sortHandOrder()
        // Should be S-A2 H-Q85 D-(none) C-32
        XCTAssertEqual(cc[0], .aceOfSpades)
        XCTAssertEqual(cc[1], .twoOfSpades)
        XCTAssertEqual(cc[2], .queenOfHearts)
        XCTAssertEqual(cc[3], .eightOfHearts)
        XCTAssertEqual(cc[4], .fiveOfHearts)
        XCTAssertEqual(cc[5], .threeOfClubs)
        XCTAssertEqual(cc[6], .twoOfClubs)
        
        cc.sortBySuit()
        XCTAssertEqual(cc[0], .twoOfClubs)
        XCTAssertEqual(cc[6], .aceOfSpades)
    }

    

    func testFilterBySuit() throws {
        let hand: [Card] = [.kingOfDiamonds, .jackOfClubs, .kingOfClubs, .queenOfClubs, .aceOfClubs, .fourOfHearts, .threeOfHearts, .twoOfHearts]
        XCTAssert(hand.filter(by: .diamonds).contains(Card(.king, .diamonds)))
        XCTAssertEqual(hand.filter(by: .clubs).count, 4)
        XCTAssertEqual(hand.filter(by: .hearts)[0], .fourOfHearts)
    }

    func testRemoveFirst() throws {

        var hand: [Card] = [.queenOfSpades, .kingOfSpades, .jackOfSpades, .jackOfSpades, .jackOfSpades]
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), .jackOfSpades)
        XCTAssertNil(hand.removeFirst(Card(.jack, .spades)))

        var cc: [Card] = [.aceOfSpades, .kingOfSpades, .queenOfSpades, .twoOfHearts, .threeOfHearts, .fourOfHearts]

        let removed = cc.removeFirst(.kingOfSpades)
        XCTAssertEqual(removed, Card(.king, .spades))
        let removeSameCard = cc.removeFirst(Card(.king, .spades))
        XCTAssertNil(removeSameCard)
        _ = cc.removeFirst(Card(.three, .hearts))
        XCTAssertEqual(cc, [.aceOfSpades, .queenOfSpades, .twoOfHearts, .fourOfHearts])
        
        cc = Array<Card>(repeating: .fourOfDiamonds, count: 3)
        cc.append(Card(.ace, .spades))
        XCTAssertEqual(cc, [.fourOfDiamonds, .fourOfDiamonds, .fourOfDiamonds, .aceOfSpades])
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc, [.fourOfDiamonds, .fourOfDiamonds, .aceOfSpades])
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc, [.fourOfDiamonds, .aceOfSpades])
    }
    
 
    /*
    func testValidate() throws {
        let ccDupCard: Array<Card> = [Card(.two, .clubs), Card(.ace, .spades), Card(.two, .clubs)]
        var caughtDuplicate = false
        do {
            try ccDupCard.validate()
        } catch CardArrayError.duplicateCard(let card) {
            caughtDuplicate = true
            XCTAssertEqual(card, Card(.two, .clubs))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssert(caughtDuplicate)
        
        let ccTooShort = try! Array<Card>.fromSerialized("aj5.t37.2.6")
        do {
            try ccTooShort.validate(requireFullHand: false)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        var caughtPartialHand = false
        do {
            try ccTooShort.validate(requireFullHand: true)
        } catch CardArrayError.notFullHand(let count) {
            XCTAssertEqual(count, 8)
            caughtPartialHand = true
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssert(caughtPartialHand)
        
        let ccFullValid = try! Array<Card>.fromSerialized("2345.234.234.234")
        XCTAssertNoThrow(try ccFullValid.validate(requireFullHand: true))
        
        XCTAssertNoThrow(try Array<Card>.fromSerialized("aaakkkqqq", allowDuplicates: true))
        XCTAssertThrowsError(try Array<Card>.fromSerialized("aakqj"))
    }
    */

}
