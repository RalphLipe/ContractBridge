//
//  CardCombinationAnalyzerTest.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import XCTest
import ContractBridge

class CardCombinationAnalyzerTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    private func reportResults(analysis: LayoutAnalysis) -> Void {
        print("Total combinations considered: \(analysis.totalCombinations)")
        for result in analysis.bestLeads() {
            print("\(result.leadPlan) ")
            print("   tricks: ", terminator: "")
            var desired = analysis.worstCaseTricks + 1
            var printedTricks = false
            while result.combinationsFor(desiredTricks: desired) > 0 {
                print("\(desired): \(result.combinationsFor(desiredTricks: desired)) - \(result.percentageFor(desiredTricks: desired))%   ", terminator: "")
                printedTricks = true
                desired += 1
            }
            print(printedTricks ? "" : "worst case")
            print("For specific layout makes \(result.maxTricksThisLayout) tricks")
            print("Trick won by \(result.trickSequence.winningPosition)")
            for (position, ranks) in result.trickSequence.play {
                print("  \(position) plays \(ranks)")
            }
        }
    }

    
    func testExample() throws {
        let layout = SuitLayout(suit: .spades, north: [.ace, .nine, .three, .two], south: [.king, .ten])
        let sh = SuitHolding(suitLayout: layout)
        let analysis = CardCombinationAnalyzer.analyze(suitHolding: sh)
        reportResults(analysis: analysis)
        
        let bestLeads = analysis.bestLeads()
        let layoutInfo = bestLeads[0].layoutsFor(analysis.maxTricksAllLayouts)
        let bestLayout = SuitLayout(suitLayoutId: layoutInfo[0].layoutId!)
        let bestHolding = SuitHolding(suitLayout: bestLayout)
        
        print("NOW FOR ONLY BEST HOLDING:")
        while bestHolding[.north].count > 0 || bestHolding[.south].count > 0 {
            let a2 = CardCombinationAnalyzer.analyze(suitHolding: bestHolding)
            reportResults(analysis: a2)
            bestHolding.playCards(from: a2.bestLeads()[0].trickSequence.play)
            print("**************************************************************")
            print("North has \(bestHolding[.north].count) cards.  South has \(bestHolding[.south].count)")
        }
    }
/*
    func testPerformanceExample() throws {
        // This is an example of a performance test case.l
        self.measure {
            var deal = Deal()
            deal[.north] = [.aceOfSpades, .nineOfSpades, .threeOfSpades, .twoOfSpades]
            deal[.south] = [.kingOfSpades, .tenOfSpades]
            deal = DealGenerator.fillOutEWCards(partialDeal: deal, suit: .spades)
            let sh = SuitHolding(deal: deal, suit: .spades)
            let a = CardCombinationAnalyzer(suitHolding: sh)
            analysis = a.analyze()
        }
        reportResults(analysis: analysis!)
    }
*/
}
