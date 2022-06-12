//
//  RankSetTests.swift
//  
//
//  Created by Ralph Lipe on 6/7/22.
//

import XCTest
import ContractBridge

class RankSetTests: XCTestCase {

    func testInit() throws {
        let s = Set<Rank>([.jack, .queen, .three, .ace])
        XCTAssertEqual(s.serialized, "AQJ3")
        XCTAssertEqual("\(s)", s.serialized)
        XCTAssertEqual("\(s, style: .name)", "ace, queen, jack, three")
        
        let s2 = try! Set<Rank>(from: "jK4729")
        XCTAssertEqual(s2.serialized, "KJ9742")
        
        XCTAssertThrowsError(try Set<Rank>(from: "$(%"))
        
    }
    
    func testStringInterpolation() throws {
        let s = try Set<Rank>(from: "AT29Q")
        XCTAssertEqual("\(s, style: .symbol)", "AQT92")
        XCTAssertEqual("\(s, style: .character)", "A, Q, T, 9, 2")
        XCTAssertEqual("\(s, style: .name)", "ace, queen, ten, nine, two")

    }
    
}
