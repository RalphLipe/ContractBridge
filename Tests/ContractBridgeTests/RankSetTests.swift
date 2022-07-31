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
        let s = RankSet([.jack, .queen, .three, .ace])
        XCTAssertEqual(s.serialized(), "AQJ3")
        XCTAssertEqual("\(s)", s.serialized())
        XCTAssertEqual("\(s, style: .name)", "ace, queen, jack, three")
        
        let s2 = try! RankSet(from: "jK4729")
        XCTAssertEqual(s2.serialized(), "KJ9742")
        XCTAssertEqual(s2, [.king, .jack, .nine, .seven, .four, .two])
        
        XCTAssertThrowsError(try RankSet(from: "$(%"))
        
        let sLiteral: RankSet = [.two, .five, .seven, .nine]
        XCTAssertEqual(sLiteral.count, 4)
        XCTAssertTrue(sLiteral.contains(.five))
        XCTAssertFalse(sLiteral.contains(.ace))
    }
    
    func testSequence() throws {
        let s = try RankSet(from: "4AT29Q")
        let r = Array<Rank>(s)
        XCTAssertEqual(r, [.two, .four, .nine, .ten, .queen, .ace])
    }
    
    func testBasic() throws {
        var s = RankSet()
        XCTAssertEqual(s.count, 0)
        XCTAssertTrue(s.isEmpty)
        XCTAssertFalse(s.isFull)
        
        XCTAssertTrue(s.insert(.two))   // Inserted
        XCTAssertFalse(s.insert(.two))  // not inserted
        
        XCTAssertFalse(s.isEmpty)
        XCTAssertEqual(s.count, 1)
        
        XCTAssertNil(s.remove(.five))
        XCTAssertEqual(s.count, 1)
        XCTAssertEqual(s.remove(.two), .two)
        XCTAssertTrue(s.isEmpty)
        
        s.insertAll()
        XCTAssertTrue(s.isFull)
        XCTAssertEqual(s.count, Rank.allCases.count)
        
        s.remove(.two)
        s.remove(.four)
        XCTAssertEqual(s.removeFirst(), .three)
        XCTAssertEqual(s.count, 10)
        XCTAssertEqual(s.removeFirst(), .five)
        
        XCTAssertEqual(s.min(), .six)
        
        s.removeAll()
        XCTAssertTrue(s.isEmpty)
        XCTAssertEqual(s.count, 0)
    }
    
    func testMinMax() throws {
        var s: RankSet = [.four, .king, .jack, .three, .eight]
        XCTAssertEqual(s.min(), .three)
        XCTAssertEqual(s.max(), .king)
        s.remove(.king)
        s.remove(.three)
        XCTAssertEqual(s.max(), .jack)
        XCTAssertEqual(s.min(), .four)
        s.remove(.four)
        s.remove(.jack)
        XCTAssertEqual(s.min(), s.max())
        XCTAssertEqual(s.max(), .eight)
        s.remove(.eight)
        XCTAssert(s.isEmpty)
        XCTAssertNil(s.max())
        XCTAssertNil(s.min())
        
    }
    
    func testUnion() throws {
        let s1: RankSet = [.four, .five, .queen]
        var s2: RankSet = [.eight, .five, .ace]
        s2.formUnion(s1)
        XCTAssertEqual(s2.count, 5)
        let a = Array<Rank>(s2)
        XCTAssertEqual(a, [.four, .five, .eight, .queen, .ace])
        
        let s3: RankSet = [.king, .ace]
        let s4 = s1.union(s3)
        let s = s4.serialized()
        XCTAssertEqual(s, "AKQ54")
    }
    
    func testIntersection() throws {
        let s1: RankSet = [.four, .five, .queen]
        var s2: RankSet = [.eight, .five, .ace]
        s2.formIntersection(s1)
        XCTAssertEqual(s2.count, 1)
        XCTAssertTrue(s2.contains(.five))
        
        let s3: RankSet = [.four, .queen, .ten]
        let s4 = s1.intersection(s3)
        let s = s4.serialized()
        XCTAssertEqual(s, "Q4")
    }
    
    func testSerialized() throws {
        let s: RankSet = [.five, .nine, .ace, .four]
        XCTAssertEqual(s.serialized(), "A954")
    }
    
    func testStringInterpolation() throws {
        let s = try RankSet(from: "AT29Q")
        XCTAssertEqual("\(s, style: .symbol)", "AQT92")
        XCTAssertEqual("\(s, style: .character)", "A, Q, T, 9, 2")
        XCTAssertEqual("\(s, style: .name)", "ace, queen, ten, nine, two")

    }
    
}
