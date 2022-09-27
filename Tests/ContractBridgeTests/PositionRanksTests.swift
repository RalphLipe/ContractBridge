//
//  PositionRanksTests.swift
//  
//
//  Created by Ralph Lipe on 9/22/22.
//

import XCTest
import ContractBridge

class PositionRanksTests: XCTestCase {


    func testBasic() throws {
        var pr = PositionRanks()
        XCTAssertEqual(pr.count, 0)
        XCTAssertNil(pr[.north])
        XCTAssertNil(pr.winning)
        XCTAssertTrue(pr.isEmpty)
        
        pr[.south] = .eight
        XCTAssertEqual(pr.count, 1)
        XCTAssertEqual(pr.winning?.position, .south)
        XCTAssertEqual(pr.winning?.rank, .eight)
        XCTAssertFalse(pr.isEmpty)
        
        pr[.east] = .nine
        XCTAssertEqual(pr.count, 2)
        XCTAssertEqual(pr.winning?.position, .east)
        XCTAssertEqual(pr.winning?.rank, .nine)
        XCTAssertFalse(pr.isEmpty)

        pr[.south] = .jack
        XCTAssertEqual(pr.count, 2)
        XCTAssertEqual(pr.winning?.position, .south)
        XCTAssertEqual(pr.winning?.rank, .jack)
        XCTAssertFalse(pr.isEmpty)
        
        pr[.west] = .ace
        pr[.north] = .two
        XCTAssertEqual(pr.count, 4)
        XCTAssertEqual(pr.winning?.position, .west)
        XCTAssertEqual(pr.winning?.rank, .ace)
        XCTAssertFalse(pr.isEmpty)
        
        var pr2 = pr
        XCTAssertEqual(pr, pr2)
        
        pr2[.north] = nil
        XCTAssertNotEqual(pr, pr2)
        XCTAssertEqual(pr2.count, 3)
        
        pr2[.north] = pr[.north]
        XCTAssertEqual(pr, pr2)
    }



}
