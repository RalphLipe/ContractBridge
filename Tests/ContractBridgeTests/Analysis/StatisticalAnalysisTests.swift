//
//  StatisticalAnalysisTests.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import XCTest
import ContractBridge

class StatisticalAnalysisTests: XCTestCase {

    
       
    func printAnalysis(holding: RankPositions, analysis: StatisticalAnalysis) {
        
        let bestStats = analysis.bestStats
        print("Analysis for \(holding) needing \(analysis.requiredTricks) tricks")
        if analysis.leadOption == .leadHigh { print("* Only considering leading high *") }
        print("Best leads make \(bestStats.percentMaking)% of the time making average of \(bestStats.averageTricks) tricks")
       // let leadStats = analysis.leadStatistics
        var makingV = Set<VariableRankPositions.Variant>()
        for lead in analysis.bestLeads {
            print("    \(lead)")
            for variant in analysis.holding.variants {
                if analysis.leadAnalyses(for: variant)[lead]!.stats.percentMaking == 100.0 {
                    makingV.insert(variant)
                    print("      \(variant.combinations) - \(variant.representativeLayout)")
                }
            }
        }
        print("Other leads:")
        for (lead, stats) in analysis.leadStatistics {
            if !analysis.bestLeads.contains(lead) {
                print("    \(lead) \(stats.percentMaking) \(stats.averageTricks)")
                for variant in makingV {
                    let a = analysis.leadAnalyses(for: variant)[lead]!
                    print("      \(variant.combinations) - \(variant.representativeLayout) \(a.stats.percentMaking)% \(a.stats.averageTricks) tricks")
                    print("           \(a.play)")
                    if lead.intent == .cashWinner && a.stats.percentMaking == 0.0 {
                        print("THIS SHOULD MAKE.  LETS LOOK ONE DOWN...")
                        let nextVar = variant.play(leadPosition: lead.position, play: a.play)
                        print("Next variant: \(nextVar.representativeLayout)")
                        let nextAnalysis = StatisticalAnalysis.analyze(holding: VariableRankPositions(from: nextVar), leadPair: .ns, requiredTricks: 5, cache: nil)
                        print("*** AFTER FIRST CASH WINNER BEST ODDS FOR 5 TRICKS: \(nextAnalysis.bestStats.percentMaking)%")
                        for lead in nextAnalysis.bestLeads {
                            print("    **\(lead)")
                            for variant in nextAnalysis.holding.variants {
                                if nextAnalysis.leadAnalyses(for: variant)[lead]!.stats.percentMaking == 100.0 {
                                    print("      **\(variant.combinations) - \(variant.representativeLayout)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func analyze(_ s: String, tricksRequired: Int, percentMaking: Double? = nil, averageTricks: Double? = nil, leadOption: LeadOption = .considerAll, cache: StatsCache? = nil, leadIntent: LeadPlan.Intent? = nil, verbose: Bool = false) {
        let deal = try! Deal(from: s)
        let holding = RankPositions(hands: deal.hands, suit: .spades)
        let vrp = VariableRankPositions(partialHolding: holding, variablePair: .ew)
        let analysis = StatisticalAnalysis.analyze(holding: vrp, leadPair: .ns, requiredTricks: tricksRequired, leadOption: leadOption, cache: cache)
        let bestStats = analysis.bestStats
        
        if let averageTricks = averageTricks {
            XCTAssertEqual(averageTricks, bestStats.averageTricks)
        }
        if let percentMaking = percentMaking {
            XCTAssertEqual(percentMaking, bestStats.percentMaking)
        }
        if let leadIntent = leadIntent {
            XCTAssertEqual(analysis.bestLeads.first!.intent, leadIntent)
        }
        if verbose {
            printAnalysis(holding: holding, analysis: analysis)
            print("")
        }
    }

    func testBasicFinesse() throws {
        analyze("N:AQ - 2 -", tricksRequired: 2, percentMaking: 50.0, averageTricks: 1.5)
        analyze("N:KQ2 - 345 -", tricksRequired: 2, percentMaking: 50.0, averageTricks: 1.5)
        
        // Now put some E/W cards  in known places...
        analyze("N:AQ - 2 K", tricksRequired: 2, percentMaking: 100.0, averageTricks: 2.0, leadIntent: .finesse)
        analyze("N:KQ2 - 345 A", tricksRequired: 2, percentMaking: 100.0, averageTricks: 2.0, leadIntent: .finesse)
        analyze("N:AQ K 2 -", tricksRequired: 2, leadIntent: .cashWinner) // cash winner is only way to get 2 when singleton K
    }
    
    func test440() throws {
        analyze("N:KQ543 - T2 -", tricksRequired: 2)
        analyze("N:KQ543 - T2 -", tricksRequired: 3)
        analyze("N:KQ543 - T2 -", tricksRequired: 4)
    }
    
    // TODO: We need to verify that correct lead sequence is used....  At least first lead
    func test450() throws {
        analyze("N:KQ76543 - 2 -", tricksRequired: 5, leadIntent: .playLow)
        analyze("N:KQ76543 - 2 -", tricksRequired: 6, leadIntent: .finesse)
    }

    func testSeemStrange() throws {
        analyze("N:AT9843 - K2 -", tricksRequired: 0)
        analyze("N:AT9843 - K2 -", tricksRequired: 6, verbose: true)
    }
    
}
