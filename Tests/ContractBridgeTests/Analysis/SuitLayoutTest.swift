//
//  SuitLayoutTest.swift
//  
//
//  Created by Ralph Lipe on 5/13/22.
//

import XCTest
import ContractBridge

class SuitLayoutTest: XCTestCase {


    func testInit() throws {
        var l = SuitLayout()
        XCTAssertNil(l[.two])
        XCTAssertNil(l[.ace])
        XCTAssertEqual(l.id, 0)
        
        l[.four] = .north
        l[.eight] = .south
        
        XCTAssertFalse(l.isFullLayout)
        let l2 = l  // Make a copy
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
    
    func testIsFullLayout() throws {
        var layout = SuitLayout()
        XCTAssertFalse(layout.isFullLayout)
        layout[.two] = .north
        XCTAssertFalse(layout.isFullLayout)
        Rank.allCases.forEach { layout[$0] = .east }
        XCTAssertTrue(layout.isFullLayout)
        layout[.jack] = nil
        XCTAssertFalse(layout.isFullLayout)
        layout[.jack] = .north
        XCTAssertTrue(layout.isFullLayout)
    }
    
    func testID() throws {
        var layout = SuitLayout()
        XCTAssertEqual(layout.id, 0)
        layout[.two] = .north
        XCTAssertNotEqual(layout.id, 0)
        
        // TODO: More tests here
    }
    
    // TODO: Write these tests...
    func testAssignNilPositions() throws {
        var layout = SuitLayout()
        layout[.seven] = .north
        layout.assignNilPositions(.south)
        XCTAssert(layout.isFullLayout)
        XCTAssertEqual(layout[.seven], .north)
        XCTAssertEqual(layout[.ace], .south)
    }
    
    func testAssignRanks() throws {
        var layout = SuitLayout()
        layout.assign(ranks: [.five, .jack, .ace], position: .north)
        XCTAssertEqual(layout.count, 3)
        XCTAssertEqual(layout[.jack], .north)
        layout.assign(ranks: [.two, .three, .queen], position: .south)
        XCTAssertEqual(layout.count, 6)
        XCTAssertEqual(layout[.three], .south)
    }
    
    func testRanksFor() throws {
        
    }
    
    func testCountFor() throws {
        
    }
    
    func testReassignRanks() throws {
        
    }
    
    func testPairRanges() throws {
        var layout = SuitLayout()
        var pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 1)
        XCTAssertEqual(pairRanges[0].pair, nil)
        XCTAssertEqual(pairRanges[0].range, Rank.two...Rank.ace)
        
        layout.assignNilPositions(.north)
        pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 1)
        XCTAssertEqual(pairRanges[0].pair, .ns)
        XCTAssertEqual(pairRanges[0].range, Rank.two...Rank.ace)
        
        layout[.seven] = .south
        pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 1)
        XCTAssertEqual(pairRanges[0].pair, .ns)
        XCTAssertEqual(pairRanges[0].range, Rank.two...Rank.ace)
        
        layout[.eight] = nil
        pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 3)
        XCTAssertEqual(pairRanges[0].pair, .ns)
        XCTAssertEqual(pairRanges[0].range, Rank.two...Rank.seven)
        XCTAssertEqual(pairRanges[1].pair, nil)
        XCTAssertEqual(pairRanges[1].range, Rank.eight...Rank.eight)
        XCTAssertEqual(pairRanges[2].pair, .ns)
        XCTAssertEqual(pairRanges[2].range, Rank.nine...Rank.ace)
        
        let deal = try! Deal(from: "N:AK23. 965... QT7... J84...")
        layout = SuitLayout(deal: deal, suit: .spades)
        XCTAssertTrue(layout.isFullLayout)
  
        pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 7)
        XCTAssertEqual(pairRanges[0].pair, .ns)
        XCTAssertEqual(pairRanges[0].range, Rank.two...Rank.three)
        XCTAssertEqual(pairRanges[1].pair, .ew)
        XCTAssertEqual(pairRanges[1].range, Rank.four...Rank.six)
        XCTAssertEqual(pairRanges[2].pair, .ns)
        XCTAssertEqual(pairRanges[2].range, Rank.seven...Rank.seven)
        XCTAssertEqual(pairRanges[3].pair, .ew)
        XCTAssertEqual(pairRanges[3].range, Rank.eight...Rank.nine)
        XCTAssertEqual(pairRanges[4].pair, .ns)
        XCTAssertEqual(pairRanges[4].range, Rank.ten...Rank.ten)
        XCTAssertEqual(pairRanges[5].pair, .ew)
        XCTAssertEqual(pairRanges[5].range, Rank.jack...Rank.jack)
        XCTAssertEqual(pairRanges[6].pair, .ns)
        XCTAssertEqual(pairRanges[6].range, Rank.queen...Rank.ace)
        
        layout[.king] = nil
        
        pairRanges = layout.pairRanges()
        XCTAssertEqual(pairRanges.count, 9)
        XCTAssertEqual(pairRanges[6].pair, .ns)
        XCTAssertEqual(pairRanges[6].range, Rank.queen...Rank.queen)
        XCTAssertEqual(pairRanges[7].pair, nil)
        XCTAssertEqual(pairRanges[7].range, Rank.king...Rank.king)
        XCTAssertEqual(pairRanges[8].pair, .ns)
        XCTAssertEqual(pairRanges[8].range, Rank.ace...Rank.ace)

    }


}
