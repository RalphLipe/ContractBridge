//
//  DirectionTests.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class DirectionTests: XCTestCase {

    func testInit() throws {
        XCTAssertNil(Direction(from: "broken"))
        XCTAssertEqual(Direction(from: "north"), .north)
        XCTAssertEqual(Direction(from: "E"), .east)
    }

    func testNext() throws {
        XCTAssertEqual(Direction.north.next, Direction.east)
        XCTAssertEqual(Direction(from: "E")!.next, Direction.south)
        XCTAssertEqual(Direction(from: "south")!.next, Direction.west)
        XCTAssertEqual(Direction.west.next, Direction.north)
    }
    
    func testPartner() throws {
        XCTAssertEqual(Direction.north.partner, Direction.south)
        XCTAssertEqual(Direction(from: "east")!.partner, Direction.west)
        XCTAssertEqual(Direction(from: "S")!.partner, Direction.north)
        XCTAssertEqual(Direction.west.partner, Direction.east)
    }
  
    func testPrevious() throws {
        XCTAssertEqual(Direction.north.previous, Direction.west)
        XCTAssertEqual(Direction(from: "E")!.previous, Direction.north)
        XCTAssertEqual(Direction(from: "south")!.previous, Direction.east)
        XCTAssertEqual(Direction.west.previous, Direction.south)
    }


    func testStringInterpolation() throws {
        var s = ""
        for direction in Direction.allCases {
            s += "\(direction)"
        }
        XCTAssertEqual(s, "NESW")
    }
}
