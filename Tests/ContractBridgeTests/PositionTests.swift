//
//  PositionTests.swift
//  
//
//  Created by Ralph Lipe on 3/11/22.
//

import XCTest
import ContractBridge

class PositionTests: XCTestCase {

    func testInit() throws {
        XCTAssertNil(Position(from: "broken"))
        XCTAssertEqual(Position(from: "north"), .north)
        XCTAssertEqual(Position(from: "E"), .east)
    }

    func testNext() throws {
        XCTAssertEqual(Position.north.next, Position.east)
        XCTAssertEqual(Position(from: "E")!.next, Position.south)
        XCTAssertEqual(Position(from: "south")!.next, Position.west)
        XCTAssertEqual(Position.west.next, Position.north)
    }
    
    func testPartner() throws {
        XCTAssertEqual(Position.north.partner, Position.south)
        XCTAssertEqual(Position(from: "east")!.partner, Position.west)
        XCTAssertEqual(Position(from: "S")!.partner, Position.north)
        XCTAssertEqual(Position.west.partner, Position.east)
    }
  
    func testPrevious() throws {
        XCTAssertEqual(Position.north.previous, Position.west)
        XCTAssertEqual(Position(from: "E")!.previous, Position.north)
        XCTAssertEqual(Position(from: "south")!.previous, Position.east)
        XCTAssertEqual(Position.west.previous, Position.south)
    }


    func testShortDescription() throws {
        var s = ""
        for position in Position.allCases {
            s += position.shortDescription
        }
        XCTAssertEqual(s, "NESW")
    }
}
