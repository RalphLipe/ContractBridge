//
//  DealTests.swift
//  
//
//  Created by Ralph Lipe on 3/23/22.
//

import XCTest
import ContractBridge

class DealTests: XCTestCase {

    func testInit() throws {
        let noHands = Deal()
        XCTAssertNil(noHands.hands[.north])
        XCTAssertNil(noHands.hands[.south])
        XCTAssertNil(noHands.hands[.east])
        XCTAssertNil(noHands.hands[.west])
        
        
        
        let deal = try! Deal(from: "N:AKQ.432.432.AKQJ - 234... -")
        XCTAssertEqual(deal.hands[.north]!.count, 13)
        XCTAssertEqual(deal.hands[.east], nil)
        XCTAssertEqual(deal.hands[.south]!.count, 3)
        
        
        XCTAssertTrue(deal.hands[.south]!.contains(Card(.four, .spades)))
    }
    
    // TODO:  Need to test codable encode/decode
    
    func testSerialize() throws {
        var deal = Deal()
        deal.hands[.north] = [.twoOfSpades]
        var ser = deal.serialize(startPosition: .north)
        XCTAssertEqual(ser, "N:2... - - -")
        
        deal.hands[.south] = [.jackOfClubs, .twoOfClubs, .aceOfClubs, .kingOfClubs, .sevenOfDiamonds]
        ser = deal.serialize(startPosition: .north)
        XCTAssertEqual(ser, "N:2... - ..7.AKJ2 -")
        
    }
    
    // TODO: Check for actual errors here
    
    func testValidate() throws {
        var deal = try Deal(from: "N:AKQJ.AKQ.AKQ.AKQ T98.JT98.JT9.JT9 765.765.8765.876 432.432.432.5432")
        XCTAssertNoThrow(try deal.validate())
        deal.hands[.north]!.remove(.aceOfSpades)
        XCTAssertThrowsError(try deal.validate())
        XCTAssertNoThrow(try deal.validate(fullDeal: false))
        deal.hands[.north]!.insert(.twoOfClubs)
        XCTAssertThrowsError(try deal.validate(fullDeal: false))
    }
}
