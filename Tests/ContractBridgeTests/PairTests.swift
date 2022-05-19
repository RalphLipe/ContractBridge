//
//  PairTests.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class PairTest: XCTestCase {

    
    func testPair() throws {
        XCTAssertEqual(Position(from: "n")!.pair, Pair.ns)
        XCTAssertEqual(Position(from: "east")!.pair, Pair.ew)
        XCTAssertEqual(Position.south.pair, Pair.ns)
        XCTAssertEqual(Position(from: "W")!.pair, Pair.ew)
        XCTAssertEqual(Pair.ns.opponents, Pair.ew)
        XCTAssertEqual(Pair.ew.opponents, Pair.ns)
        XCTAssertEqual(Position.north.pair.positions.0, .north)
        XCTAssertEqual(Position.north.pair.positions.1, .south)
        XCTAssertEqual(Position.east.pair.positions.0, .east)
        XCTAssertEqual(Position.east.pair.positions.1, .west)
    }

}
