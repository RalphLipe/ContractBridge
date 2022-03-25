//
//  RankTests.swift
//  
//
//  Created by Ralph Lipe on 3/23/22.
//

import XCTest
import ContractBridge

class RankTests: XCTestCase {


    func testInit() throws {
        XCTAssertEqual(Rank(from: "queen"), Rank.queen)
        XCTAssertEqual(Rank(from: "aCe"), Rank.ace)
        XCTAssertNil(Rank(from: "silly"))
    }

    func testNextLower() throws {
        XCTAssertNil(Rank.two.nextLower)
        XCTAssertEqual(Rank.ten.nextLower, Rank.nine)
        XCTAssertEqual(Rank.ace.nextLower, Rank.king)
    }
    
    func testNextHigher() throws {
        XCTAssertNil(Rank.ace.nextHigher)
        XCTAssertEqual(Rank.king.nextHigher, Rank.ace)
        XCTAssertEqual(Rank.two.nextHigher, Rank.three)
    }
    
    func testRange() throws {
        let range = Rank.four...Rank.eight
        XCTAssertTrue(range.contains(.eight))
        XCTAssertFalse(range.contains(.ace))
        XCTAssertTrue(range.contains(.six))
        XCTAssertTrue(Rank.two < Rank.three)
        XCTAssertEqual(Rank.two.distance(to: .six), 4)
        
        let lowCards = Rank.two...Rank.ten
        let honors = Rank.jack...Rank.ace
        XCTAssertFalse(lowCards.overlaps(honors))
    }
    

    
}
