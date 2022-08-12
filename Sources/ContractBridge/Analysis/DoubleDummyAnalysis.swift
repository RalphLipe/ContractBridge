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
    public let maxTricksTaken: Int
    
    internal init(holding: RankPositions, leadPair: Pair, leadOption: LeadOption, leadAnalyses: inout [LeadPlan: LeadAnalysis]?) {
        self.holding = holding
        self.leadPair = leadPair
        self.leadOption = leadOption
        var max = -1
        LeadGenerator.generateLeads(rankPositions: holding, pair: leadPair, option: leadOption).forEach {
            leadPlan in
            let result = LeadAnalyzer.doubleDummy(holding: holding, leadPlan: leadPlan, leadOption: leadOption)
            if result.tricksTaken > max { max = result.tricksTaken }
            if leadAnalyses != nil { leadAnalyses![leadPlan] = result }
        }
        self.maxTricksTaken = max
    }
    
    public init(holding: RankPositions, leadPair: Pair, leadOption: LeadOption = .considerAll) {
        var analyses: [LeadPlan: LeadAnalysis]? = nil
        self.init(holding: holding, leadPair: leadPair, leadOption: leadOption, leadAnalyses: &analyses)
    }
    
}

public struct DoubleDummyWithLeads {
    public let analysis: DoubleDummyAnalysis
    public let leadAnalyses: [LeadPlan: LeadAnalysis]

    public init(holding: RankPositions, leadPair: Pair, leadOption: LeadOption = .considerAll) {
        var analyses: [LeadPlan : LeadAnalysis]? = [LeadPlan: LeadAnalysis]()
        self.analysis = DoubleDummyAnalysis(holding: holding, leadPair: leadPair, leadOption: leadOption, leadAnalyses: &analyses)
        self.leadAnalyses = analyses!
    }
    
    public var bestLeads: Set<LeadPlan> {
        return leadsMaking(exactly: analysis.maxTricksTaken)
    }
    
    public func leadsMaking(exactly tricksTaken: Int) -> Set<LeadPlan> {
        var leads = Set<LeadPlan>()
        leadAnalyses.forEach {
            leadPlan, analysis in
            if analysis.tricksTaken == tricksTaken { leads.insert(leadPlan) }
        }
        return leads
    }
}

