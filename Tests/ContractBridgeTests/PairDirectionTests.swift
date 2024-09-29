//
//  PairDirectopmTests.swift
//
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class PairDirectionTests: XCTestCase {

    
    func testPair() throws {
        XCTAssertEqual(Direction(from: "n")!.pairDirection, PairDirection.ns)
        XCTAssertEqual(Direction(from: "east")!.pairDirection, PairDirection.ew)
        XCTAssertEqual(Direction.south.pairDirection, PairDirection.ns)
        XCTAssertEqual(Direction(from: "W")!.pairDirection, PairDirection.ew)
        XCTAssertEqual(PairDirection.ns.opponents, PairDirection.ew)
        XCTAssertEqual(PairDirection.ew.opponents, PairDirection.ns)
        XCTAssertEqual(Direction.north.pairDirection.directions.0, .north)
        XCTAssertEqual(Direction.north.pairDirection.directions.1, .south)
        XCTAssertEqual(Direction.east.pairDirection.directions.0, .east)
        XCTAssertEqual(Direction.east.pairDirection.directions.1, .west)
    }
    
    func testStringInterpolation() throws {
        let ns = PairDirection.ns
        let ew = PairDirection.ew
        XCTAssertEqual("\(ns)", "N/S")
        XCTAssertEqual("\(ew)", "E/W")
        XCTAssertEqual("\(ns, style: .name)", "north/south")
        XCTAssertEqual("\(ew, style: .name)", "east/west")

    }

}
