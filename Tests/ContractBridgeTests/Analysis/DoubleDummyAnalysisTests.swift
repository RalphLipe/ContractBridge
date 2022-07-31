//
//  DoubleDummyAnalysisTests.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import XCTest
import ContractBridge

class DoubleDummyAnalysisTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDD() throws {
        var holding = RankPositions()
        holding[.north] = [.ace, .queen]
        holding[.south] = [.two]
        holding.reassignRanks(from: nil, to: .west)
        holding[.king] = .east
        let dd = DoubleDummyAnalysis(holding: holding, leadPair: .ns)
        for leadAnalysis in dd.leadAnalyses {
            print("\(leadAnalysis.leadPlan) makes \(leadAnalysis.tricksTaken)")
        }
        let bestLead = dd.leadAnalyses.last!
        XCTAssertEqual(bestLead.tricksTaken, 2)
        
        holding[.king] = .west
        holding[.ten] = .east
        
        let dd2 = DoubleDummyAnalysis(holding: holding, leadPair: .ns)
        for leadAnalysis in dd2.leadAnalyses {
            print("\(leadAnalysis.leadPlan) makes \(leadAnalysis.tricksTaken)")
        }
        let bl2 = dd2.leadAnalyses.last!
        XCTAssertEqual(bl2.tricksTaken, 2)
        
        holding[.jack] = .west
        holding[.three] = .south
        holding[.ten] = .north
        
        let dd3 = DoubleDummyAnalysis(holding: holding, leadPair: .ns)
        for leadAnalysis in dd3.leadAnalyses {
            print("\(leadAnalysis.leadPlan) makes \(leadAnalysis.tricksTaken)")
        }
        let bl3 = dd3.leadAnalyses.last!
        XCTAssertEqual(bl3.tricksTaken, 3)
        
  
        
        
   // TODO: This makes no sense.  Must be 2nd hand crap MAKES: 4, comb: 6, hold: N: KQ543 E: A98 S: T2 W: J76
 
        var badComb = RankPositions()
        badComb[.north] = [.king, .queen, .five, .four, .three]
        badComb[.east] = [.ace, .nine, .eight]
        badComb[.south] = [.ten, .two]
        badComb[.west] = [.jack, .seven, .six]
        XCTAssert(badComb.isFull)
        let ddBad = DoubleDummyAnalysis(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad.leadAnalyses.last!.tricksTaken, 3)
        
        let badLead1 = ddBad.leadAnalyses.last!
        print("Trick 1 won by \(badLead1.winner)")
        var pos = badLead1.leadPlan.position
        for _ in Position.allCases {
            if let play = badLead1[pos] {
                print("\(pos): \(play)")
            }
            pos = pos.next
        }
        
        badComb[.ten] = nil
        badComb[.jack] = nil
        badComb[.queen] = nil
        badComb[.ace] = nil
        let ddBad2 = DoubleDummyAnalysis(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad2.leadAnalyses.last!.tricksTaken, 3)
        
        let badLead2 = ddBad2.leadAnalyses.last!
        print("Trick 2 won by \(badLead2.winner)")
        pos = badLead2.leadPlan.position
        for _ in Position.allCases {
            if let play = badLead2[pos] {
                print("\(pos): \(play)")
            }
            pos = pos.next
        }
        
        badComb[.king] = nil
        badComb[.two] = nil
        badComb[.six] = nil
        badComb[.eight] = nil
        let ddBad3 = DoubleDummyAnalysis(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad3.leadAnalyses.last!.tricksTaken, 2)
      
        
        let badLead3 = ddBad3.leadAnalyses.last!
        print("Trick 3 won by \(badLead3.winner)")
        pos = badLead3.leadPlan.position
        for _ in Position.allCases {
            if let play = badLead3[pos] {
                print("\(pos): \(play)")
            }
            pos = pos.next
        }
    }
    
}
