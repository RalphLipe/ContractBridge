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

    
    private func reportResults(analysis: LeadAnalysis) -> Void {
        print("Total combinations considered: \(analysis.combinations)")
        for result in analysis.leadStatistics() {
            print("\(result.lead) ")
            print("   tricks: ", terminator: "")
            var desired = analysis.worstCaseTricks + 1
            var printedTricks = false
            while result.combinationsFor(desired) > 0 {
                print("\(desired): \(result.combinationsFor(desired)) - \(result.percentageFor(desired))%   ", terminator: "")
                printedTricks = true
                desired += 1
            }
            print(printedTricks ? "" : "worst case")
        }
    }
    
    
    func testExample() throws {
        var analysis: LeadAnalysis? = nil

        var deal = Deal()
        deal[.north] = [.aceOfSpades, .nineOfSpades, .threeOfSpades, .twoOfSpades]
        deal[.south] = [.kingOfSpades, .tenOfSpades]
        deal = DealGenerator.fillOutEWCards(partialDeal: deal, suit: .spades)
        let sh = SuitHolding(deal: deal, suit: .spades)
        let a = CardCombinationAnalyzer(suitHolding: sh)
        analysis = a.analyze()
        reportResults(analysis: analysis!)
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
