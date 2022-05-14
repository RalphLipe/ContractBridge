//
//  SuitLayoutTest.swift
//  
//
//  Created by Ralph Lipe on 5/13/22.
//

import XCTest
import ContractBridge

class SuitLayoutTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        var l = SuitLayout()
        XCTAssertNil(l[.two])
        XCTAssertNil(l[.ace])
        XCTAssertEqual(l.id, 0)
        
        l[.four] = .north
        l[.eight] = .south
        
        XCTAssertFalse(l.isFullLayout)
        let l2 = SuitLayout(l)  // Make a copy
        XCTAssertEqual(l.id, l2.id)
        
        l[.ten] = .north
        XCTAssertNotEqual(l.id, l2.id)
        
        l.assignNilPositions(.east)
        XCTAssertTrue(l.isFullLayout)
        
        
        let deal = try! Deal(from: "N:AK23.J74.. 65... QT7..7654. 8...")
        let l3 = SuitLayout(deal: deal, suit: .spades)
        XCTAssertFalse(l3.isFullLayout)
        XCTAssertEqual(l3[.ace], .north)
        XCTAssertEqual(l3[.queen], .south)
        XCTAssertEqual(l3[.eight], .west)
        XCTAssertNil(l3[.four])

        let l4 = SuitLayout(suitLayoutId: l3.id)
        for rank in Rank.allCases {
            XCTAssertEqual(l3[rank], l4[rank])
        }
    }


}
