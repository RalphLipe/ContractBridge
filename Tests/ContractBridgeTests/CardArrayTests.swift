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

    func testInit() throws {
        let fromLiteral: [Card] = [Card(.ace, .diamonds), Card(.jack, .clubs)]
        
        let randomCard = fromLiteral.randomElement()!
        XCTAssertTrue(fromLiteral.contains(randomCard))
        
        XCTAssertThrowsError(try Array<Card>.fromSerialized("Bogus string"))
        XCTAssertNoThrow(try Array<Card>.fromSerialized("akq.akq.akq.akqj"))
        XCTAssertThrowsError(try Array<Card>.fromSerialized("akq.aqa.akq.2345"))    // Double ace of hearts
        XCTAssertThrowsError(try Array<Card>.fromSerialized("akq.234.akq.2345."))   // Extra "."
        
        XCTAssertEqual(try Array<Card>.fromSerialized("").count, 0)           // Blank string is valid, no cards
        XCTAssertEqual(try Array<Card>.fromSerialized("7").first, Card(.seven, .spades))
        XCTAssertEqual(try Array<Card>.fromSerialized("..4.").first, Card(.four, .diamonds))
        
    }
    
/*    func testCodable() throws {
        let encoder = JSONEncoder()
        let cc = try Array<Card>.fromSerialized("2345.234.234.qka")
        let data = try encoder.encode(cc)
        let s = String(data: data, encoding: .utf8)!
        XCTAssertEqual(s, "\"5432.432.432.AKQ\"")

        let decoder = JSONDecoder()
        let cc2 = try decoder.decode(CardCollection.self, from: data)
        XCTAssertEqual(cc.serialized, cc2.serialized)
    }
  */
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
    
    func testSerialized() throws {
        var cc: [Card] = []
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
        
        
        cc = Array<Card>.newDeck()
        XCTAssertEqual(cc.serialized, "AKQJT98765432.AKQJT98765432.AKQJT98765432.AKQJT98765432")
        cc.shuffle()
        XCTAssertEqual(cc.serialized, "AKQJT98765432.AKQJT98765432.AKQJT98765432.AKQJT98765432")
    }
    
    
/*    func testPoints() throws {
        XCTAssertEqual(try Array<Card>.fromSerialized("akq.akq.akq.akqj").highCardPoints, 37)
        XCTAssertEqual(CardCollection().highCardPoints, 0)
        XCTAssertEqual(CardCollection(numberOfDecks: 2).highCardPoints, 80)
    }
 */
    func testFilterBySuit() throws {
        let hand: [Card] = [.kingOfDiamonds, .jackOfClubs, .kingOfClubs, .queenOfClubs, .aceOfClubs, .fourOfHearts, .threeOfHearts, .twoOfHearts]
        XCTAssert(hand.filter(by: .diamonds).contains(Card(.king, .diamonds)))
        XCTAssertEqual(hand.filter(by: .clubs).count, 4)
        XCTAssertEqual(hand.filter(by: .hearts).serialized, ".432..")
    }

    func testRemoveFirst() throws {
        var hand = try Array<Card>.fromSerialized("ajt7.432.kq.at52")
        XCTAssertEqual(hand.removeFirst(Card(.ace, .clubs)), Card(.ace, .clubs))
        XCTAssertNil(hand.removeFirst(Card(.ace, .clubs)))
        
        hand = try Array<Card>.fromSerialized("QKJJJ", allowDuplicates: true)
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), Card(.jack, .spades))
        XCTAssertEqual(hand.removeFirst(Card(.jack, .spades)), .jackOfSpades)
        XCTAssertNil(hand.removeFirst(Card(.jack, .spades)))
    }
    
    func testRemoveCard() throws {
        var cc = try Array<Card>.fromSerialized("AKQ.234")
        let removed = cc.removeFirst(Card(.king, .spades))
        XCTAssertEqual(removed, Card(.king, .spades))
        let removeSameCard = cc.removeFirst(Card(.king, .spades))
        XCTAssertNil(removeSameCard)
        _ = cc.removeFirst(Card(.three, .hearts))
        XCTAssertEqual(cc.serialized, "AQ.42..")
        
        cc = Array<Card>(repeating: Card(.four, .diamonds), count: 5)
        cc.append(Card(.ace, .spades))
        XCTAssertEqual(cc.serialized, "A..44444.")
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc.serialized, "A..4444.")
        _ = cc.removeFirst(Card(.four, .diamonds))
        XCTAssertEqual(cc.serialized, "A..444.")
    }
    
 
    
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
    
    // TODO: Move these to different files
    func testSetRank() throws {
        let s = Set<Rank>([.jack, .queen, .three, .ace])
        XCTAssertEqual(s.description, "AQJ3")
        
        // MOVE THIS TOO
        let cards = Set<Card>([.aceOfClubs, .jackOfClubs, .nineOfClubs, .queenOfHearts, .threeOfHearts, .fourOfSpades])
        print("%#)%()#*)(%*#)(%*()#%*)#*%)#*()%*()#%*)(#*%)#*)%*#)%*#)%*)#*%)#*%)#*%)#*%)#*%)#*%)*%")
        print(cards.description)
    }
}
