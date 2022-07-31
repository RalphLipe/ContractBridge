//
//  DoubleDummyAnalysis.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import Foundation


public struct DoubleDummyAnalysis {
    public let holding: RankPositions
    public let leadPair: Pair
    public let leadOption: LeadOption
    public private(set) var leadAnalyses: [LeadAnalysis] = []
    
    public init(holding: RankPositions, leadPair: Pair, leadOption: LeadOption = .considerAll) {
        self.holding = holding
        self.leadPair = leadPair
        self.leadOption = leadOption
        let leads = LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption)
        for lead in leads {
            leadAnalyses.append(LeadAnalysis(holding: holding, leadPlan: lead, leadOption: leadOption))
        }
        leadAnalyses.sort(by: { $0.tricksTaken < $1.tricksTaken })
    }
}

