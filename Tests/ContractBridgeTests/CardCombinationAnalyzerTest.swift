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
    
    func printTrickSequences(_ trickSequences: [TrickSequence]) {
        for sequence in trickSequences {
            print("\(sequence.leadPlan.description) makes \(sequence.maxTricks) tricks")
            for (position, ranks) in sequence.ranks {
                print("  \(position) plays \(ranks)")
            }
        }
    }
    
    func testExample() throws {
        let layout = SuitLayout(suit: .spades, north: [.ace, .nine, .three, .two], south: [.king, .ten])
        let sh = SuitHolding(suitLayout: layout)
        let analysis = CardCombinationAnalyzer.analyzeAllEastWest(suitHolding: sh)
        let stats = analysis.leadStatistics()
        let dealInfo = stats[0].dealIdsFor(3)
        reportResults(analysis: analysis)
        let bestDeal = SuitLayout(suitLayoutId: dealInfo[0].id)
        let bestLayout = SuitLayout(suitLayoutId: bestDeal.id)
        let bestHolding = SuitHolding(suitLayout: bestLayout)
        while bestHolding[.north].count > 0 || bestHolding[.south].count > 0 {
            let trickSequences = CardCombinationAnalyzer.analyze(suitHolding: bestHolding)
            printTrickSequences(trickSequences)
            bestHolding.playCards(from: trickSequences[0])
            print("************************")
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
