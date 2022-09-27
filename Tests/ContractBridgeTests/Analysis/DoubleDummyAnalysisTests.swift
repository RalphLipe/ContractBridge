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

    func printDD(_ dd: DoubleDummyWithLeads) {
        for (leadPlan, analysis) in dd.leadAnalyses {
            print("\(leadPlan) makes \(analysis.tricksTaken)")
        }
    }
    
    func printBestLead(_ dd: DoubleDummyWithLeads) {
        let bestLead = dd.bestLeads.first!
        if let analysis = dd.leadAnalyses[bestLead] {
            print("Trick 1 won by \(analysis.winningPair)")
            var pos = bestLead.position
            for _ in Position.allCases {
                if let play = analysis.play[pos] {
                    print("\(pos): \(play)")
                }
                pos = pos.next
            }
        }
    }
    
    func testDD() throws {
        var holding = RankPositions()
        holding[.north] = [.ace, .queen]
        holding[.south] = [.two]
        holding.reassignRanks(from: nil, to: .west)
        holding[.king] = .east
        let dd = DoubleDummyWithLeads(holding: holding, leadPair: .ns)
        printDD(dd)
        XCTAssertEqual(dd.analysis.maxTricksTaken, 2)
        
        holding[.king] = .west
        holding[.ten] = .east
        
        let dd2 = DoubleDummyWithLeads(holding: holding, leadPair: .ns)
        printDD(dd2)
        XCTAssertEqual(dd2.analysis.maxTricksTaken, 2)
        
        holding[.jack] = .west
        holding[.three] = .south
        holding[.ten] = .north
        
        let dd3 = DoubleDummyAnalysis(holding: holding, leadPair: .ns)
        XCTAssertEqual(dd3.maxTricksTaken, 3)
        
  
        
        
   // TODO: This makes no sense.  Must be 2nd hand crap MAKES: 4, comb: 6, hold: N: KQ543 E: A98 S: T2 W: J76
 
        var badComb = RankPositions()
        badComb[.north] = [.king, .queen, .five, .four, .three]
        badComb[.east] = [.ace, .nine, .eight]
        badComb[.south] = [.ten, .two]
        badComb[.west] = [.jack, .seven, .six]
        XCTAssert(badComb.isFull)
        let ddBad = DoubleDummyWithLeads(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad.analysis.maxTricksTaken, 3)
        
        printBestLead(ddBad)

    
        
        badComb[.ten] = nil
        badComb[.jack] = nil
        badComb[.queen] = nil
        badComb[.ace] = nil
        let ddBad2 = DoubleDummyWithLeads(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad2.analysis.maxTricksTaken, 3)
        
        printBestLead(ddBad2)
        
        badComb[.king] = nil
        badComb[.two] = nil
        badComb[.six] = nil
        badComb[.eight] = nil
        let ddBad3 = DoubleDummyWithLeads(holding: badComb, leadPair: .ns)
        XCTAssertEqual(ddBad3.analysis.maxTricksTaken, 2)
      
        printBestLead(ddBad3)
    }
    
}
