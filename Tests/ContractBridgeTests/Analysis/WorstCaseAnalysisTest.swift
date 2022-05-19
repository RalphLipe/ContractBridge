//
//  WorstCaseAnalysisTest.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class WorstCaseAnalysisTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMinTricks() throws {
        var suitLayout = SuitLayout()
        suitLayout[.ace] = .north
        suitLayout[.queen] = .north
        XCTAssertEqual(WorstCaseAnalysis.analyze(suitLayout: suitLayout, declaringPair: .ns).tricksTaken, 2)
        XCTAssertTrue(WorstCaseAnalysis.isAllWinners(suitLayout: suitLayout, declaringPair: .ns))
        suitLayout[.king] = .east
        suitLayout[.two] = .west
        // All opponent cards should be moved to one hand so E/W cards should be treated
        // as K2 in one hand.  This should reduce winners to one...
        XCTAssertEqual(WorstCaseAnalysis.analyze(suitLayout: suitLayout, declaringPair: .ns).tricksTaken, 1)
        XCTAssertFalse(WorstCaseAnalysis.isAllWinners(suitLayout: suitLayout, declaringPair: .ns))
        suitLayout[.jack] = .south
        XCTAssertEqual(WorstCaseAnalysis.analyze(suitLayout: suitLayout, declaringPair: .ns).tricksTaken, 1)
        
        var sl2 = SuitLayout()
        sl2[.ace] = .north
        sl2[.jack] = .north
        sl2[.ten] = .north
        sl2[.queen] = .south
        sl2[.two] = .south
        sl2.assignNilPositions(.east)
        XCTAssertEqual(WorstCaseAnalysis.analyze(suitLayout: sl2, declaringPair: .ns).tricksTaken, 2)
    }


}
