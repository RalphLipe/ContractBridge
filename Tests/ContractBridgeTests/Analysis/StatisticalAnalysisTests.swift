//
//  StatisticalAnalysisTests.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import XCTest
import ContractBridge

class StatisticalAnalysisTests: XCTestCase {

    
       
       
    func analyze(north: RankSet, south: RankSet, tricksRequired: Int, leadOption: LeadOption = .considerAll) {
        var holding = RankPositions()
        holding[.north] = north
        holding[.south] = south
        print("=====================================================================")
        print("Analyzing \(holding) needing \(tricksRequired) tricks ")
        if leadOption == .leadHigh { print("***** ONLY CONSIDERING LEADING HIGH ******")}
        let stataz = StatisticalWithLeads(partialHolding: holding, requiredTricks: tricksRequired, leadOption: leadOption)
        let leadStats = stataz.leadStatistics.sorted { $0.value > $1.value }
        for (leadPlan, stats) in leadStats {
           print("\(leadPlan)")
           print("\(stataz.analysis.percentCombinationsMaking(stats))% - Avg tricks = \(stataz.analysis.averageTricks(stats))")
        }

        let best = stataz.analysis.bestStats
        print("best leads make \(best.totalTricks) tricks for \(best.combinationsMaking) combinations or \(stataz.analysis.maxTricks) tricks for best lead")
        print("percent making \(stataz.analysis.percentCombinationsMaking) for average of \(stataz.analysis.averageTricks)")
        
        let bestLeads = stataz.bestLeads
        for lead in bestLeads {
            print("\(lead)")
        }
        
        /*
           print("\(bestLeads.count) leads make \(bestLead.averageTricks) tricks for \(bestLead.percentMaking)%")
           let ts = stataz.tricksForAllLayouts(for: bestLead.leadPlan)
           for tse in ts {
               if tse.tricksTaken >= tricksRequired {
                   print("MAKES: \(tse.tricksTaken), comb: \(tse.representsCombinations), hold: \(tse.holding)")
               }
           }
           for tse in ts {
               if tse.tricksTaken < tricksRequired {
                   print("NOT MAKE: \(tse.tricksTaken), comb: \(tse.representsCombinations), hold: \(tse.holding)")
               }
           }
         */
       }

    func testBasicStat() throws {
        analyze(north: [.ace, .queen], south: [.two], tricksRequired: 2)
    }
    
    
       func testStatsAz() throws {
           /*
           analyze(north: [.ace, .queen], south: [.two], tricksRequired: 2)
           analyze(north: [.ace, .queen, .four], south: [.two, .three], tricksRequired: 2)

           analyze(north: [.ace, .queen, .ten], south: [.two, .three], tricksRequired: 3)
           
           // COMBO 458 - lead low to make 2 tricks
           // TODO: Not same lead or correct %
           analyze(north: [.king, .ten, .six, .five], south: [.queen, .four, .three, .two], tricksRequired: 2)

           // Combo 440
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 2)
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 3)
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 4)
           
        //   print("NOW STATIStical;;;;;:::")
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 0, leadOption: .leadHigh)
*/
           
       }
        
    

}
