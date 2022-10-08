//
//  StatisticalAnalysisTests.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import XCTest
import ContractBridge

class StatisticalAnalysisTests: XCTestCase {

    
       
       
    func analyze(north: RankSet, south: RankSet, tricksRequired: Int, leadOption: LeadOption = .considerAll, cache: StatsCache? = nil) {
        var holding = RankPositions()
        holding[.north] = north
        holding[.south] = south
        print("=====================================================================")
        print("Analyzing \(holding) needing \(tricksRequired) tricks ")
        if leadOption == .leadHigh { print("***** ONLY CONSIDERING LEADING HIGH ******")}
        let vh = VariableRankPositions(partialHolding: holding, variablePair: .ew)
   //     for range in vh.ranges {
   //         print(range)
   //     }
        let stataz = StatisticalAnalysis.analyze(holding: vh, leadPair: .ns, requiredTricks: tricksRequired, leadOption: leadOption, cache: cache)
        
        
        //StatisticalWithLeads(partialHolding: holding, requiredTricks: tricksRequired, leadOption: leadOption)
        /*
        let leadStats = stataz.leadStatistics.sorted { $0.value > $1.value }
        for (leadPlan, stats) in leadStats {
           print("\(leadPlan)")
           print("\(stataz.analysis.percentCombinationsMaking(stats))% - Avg tricks = \(stataz.analysis.averageTricks(stats))")
        }
         */
        let best = stataz.bestStats
        print("best leads make \(best.percentMaking)% of the time making average of \(best.averageTricks) tricks")
  
        
        let bestLeads = stataz.bestLeads
        for lead in bestLeads {
            print("BEST:  \(lead)")
        }
        print("all leads:")
        for (lead, stats) in stataz.leadStatistics {
            print("   \(lead) \(stats.percentMaking) \(stats.averageTricks)")
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
        analyze(north: [.king, .queen, .two], south: [.three, .four, .five], tricksRequired: 2)
    }
    
    
       func testStatsAz() throws {
           analyze(north: [.ace, .queen], south: [.two], tricksRequired: 2)
           analyze(north: [.ace, .queen, .four], south: [.two, .three], tricksRequired: 2)

           analyze(north: [.ace, .queen, .ten], south: [.two, .three], tricksRequired: 3)
           
           // COMBO 458 - lead low to make 2 tricks
           // TODO: Not same lead or correct %
           analyze(north: [.king, .ten, .six, .five], south: [.queen, .four, .three, .two], tricksRequired: 2)

           // Combo 440
           let cache = StatsCache()
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 2, cache: cache)
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 3, cache: cache)
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two],
                   tricksRequired: 4, cache: cache)
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 0, cache: cache)

           
           
        //   print("NOW STATIStical;;;;;:::")
           analyze(north: [.king, .queen, .five, .four, .three], south: [.ten, .two], tricksRequired: 0, leadOption: .leadHigh)
           
           // Combon 294
           analyze(north: [.king, .queen, .jack, .nine, .five, .four, .three], south: [.two], tricksRequired: 5)
           
           analyze(north: [.king, .queen, .jack, .nine, .five, .four, .three, .two], south: [], tricksRequired: 5)
           
           analyze(north: [.ace, .queen,  .five, .four, .three], south: [.jack, .ten, .two], tricksRequired: 5)
           
       }
        
    

}
