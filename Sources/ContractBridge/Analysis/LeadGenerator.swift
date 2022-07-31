//
//  LeadGenerator.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation
import AppKit

public struct RangeChoices {
    // TODO: Is this "position" a good idea?
    public let position: Position
    public let all: [RankRange]
    public let win: RankRange?
    public let mid: [RankRange]?
    public let low: RankRange?
    
    init(_ rankRanges: [RankRange], position: Position) {
        self.all = rankRanges
        self.position = position
        var r = all
        // It is important to look at the ranges in this order: Win, Low and then the rest
        // because when the final range is 2...A the last AND first are both winners and low
        self.win = r.count > 0 && r.last!.upperBound == .ace ? r.removeLast() : nil
        self.low = r.count > 0 && r.first!.lowerBound == .two ? r.removeFirst() : nil
        self.mid = r.count > 0 ? r : nil
    }
    init(rankPositions: RankPositions, position: Position) {
        self.init(rankPositions.playableRanges(for: position), position: position)
    }
}


public enum LeadOption {
    case considerAll, leadHigh
}

public struct LeadGenerator {
    private let rankPositions: RankPositions
    private let pair: Pair
    private var leads: [LeadPlan]
    private let option: LeadOption

    private init(rankPositions: RankPositions, pair: Pair, option: LeadOption) {
        self.rankPositions = rankPositions
        self.pair = pair
        self.leads = []
        self.option = option
    }

    public static func generateLeads(rankPositions: RankPositions, pair: Pair, option: LeadOption) -> [LeadPlan] {
        var generator = LeadGenerator(rankPositions: rankPositions, pair: pair, option: option)
        generator.generateLeads()
        return generator.leads
    }

    private mutating func generateLeads() {
        let choices0 = RangeChoices(rankPositions: rankPositions, position: pair.positions.0)
        let choices1 = RangeChoices(rankPositions: rankPositions, position: pair.positions.1)
        if option == .leadHigh {
            let shortSide0 = rankPositions.count(for: pair.positions.0) < rankPositions.count(for: pair.positions.1)
            if (!generateHighLead(choices: choices0, partnerChoices: choices1, isShortSide: shortSide0)) {
                generateHighLead(choices: choices1, partnerChoices: choices0, isShortSide: !shortSide0)
            }
            assert(leads.count == 1)
        } else {
            generateLeads(choices: choices0, partnerChoices: choices1)
            generateLeads(choices: choices1, partnerChoices: choices0)
        }
    }
    
    private mutating func generateHighLead(choices: RangeChoices, partnerChoices: RangeChoices, isShortSide: Bool) -> Bool {
        var lead: LeadPlan? = nil
        if !choices.all.isEmpty {
            if let win = choices.win {
                if isShortSide || partnerChoices.win == nil {
                    lead = LeadPlan(position: choices.position, lead: win, intent: .cashWinner)
                }
            } else {
                if partnerChoices.all.isEmpty {
                    lead = LeadPlan(position: choices.position, lead: choices.all.last!, intent: .ride)
                } else {
                    let max = choices.all.last!.upperBound
                    let maxPartner = partnerChoices.all.last!.upperBound
                    if max > maxPartner || (max == maxPartner && isShortSide) {
                        lead = LeadPlan(position: choices.position, lead: choices.all.last!, intent: .ride)
                    }
                }
            }
        }
        if let lead = lead {
            leads.append(lead)
            return true
        }
        return false
    }
    
    private func coverRanges(cover: RankRange, coverChoices: ArraySlice<RankRange>) -> [RankRange?] {
        var ranges = Array<RankRange?>()
        var lastRange = cover
        var mustCover: RankRange? = nil
        // Starting with the first range and moving up, if the next range has a gap of one card
        // then we will always cover it, so we don't want to generate an uncovered finesse.
        // **** TODO: Make sure this logic still is right...
        for coverChoice in coverChoices {
            if coverChoice.lowerBound.nextLower != lastRange.upperBound.nextHigher {
                // Gap of > 1 card, so add this to the list (could be nil if first range has gap)
                ranges.append(mustCover)
            }
            mustCover = coverChoice
            lastRange = coverChoice
        }
        ranges.append(mustCover)
        return ranges
    }
    
    private mutating func generateFinesses(position: Position, leadRange: RankRange, partnerChoices: RangeChoices)  {
        for i in partnerChoices.all.indices {
            let finesseRange = partnerChoices.all[i]
            if leadRange.upperBound < finesseRange.upperBound &&
                finesseRange.upperBound < .ace {
                let coverRanges = i == partnerChoices.all.endIndex ? [nil] : coverRanges(cover: finesseRange, coverChoices: partnerChoices.all[(i + 1)...])
                for coverRange in coverRanges {
                    leads.append(LeadPlan(position: position, lead: leadRange, intent: .finesse, minThirdHand: finesseRange, maxThirdHand: coverRange))
                }
            }
        }
    }

    private mutating func generateRides(position: Position, leadRange: RankRange, partnerChoices: RangeChoices)  {
        var didSomething = false
        for i in partnerChoices.all.indices {
            if leadRange.upperBound < partnerChoices.all[i].upperBound {
                let coverRanges = coverRanges(cover: leadRange, coverChoices: partnerChoices.all[i...])
                for coverRange in coverRanges {
                    leads.append(LeadPlan(position: position, lead: leadRange, intent: .ride, minThirdHand: nil, maxThirdHand: coverRange))
                    didSomething = true
                    
                }
                break
            }
        }
        if !didSomething {
            leads.append(LeadPlan(position: position, lead: leadRange, intent: .ride, minThirdHand: nil, maxThirdHand: nil))
        }
    }
    
    


    private mutating func generateLeads(choices: RangeChoices, partnerChoices: RangeChoices) {
        if choices.all.count == 0 {
            return
        }
        let position = choices.position
        if partnerChoices.all.count == 0 {
            if let winners = choices.win {
                leads.append(LeadPlan(position: position, lead: winners, intent: .cashWinner))
            } else if let low = choices.low {
                leads.append(LeadPlan(position: position, lead: low, intent: .playLow))
            } else {
                leads.append(LeadPlan(position: position, lead: choices.mid![0], intent: .ride))
            }
            return
        }
        // TODO: Perhaps if next position shows out then we could avoid generating some of these leads.
        if let low = choices.low {
            generateFinesses(position: position, leadRange: low, partnerChoices: partnerChoices)
            // TODO:  Both of the following are symetrica -- don't do it again.  Just replicate it
        ///    let lowRank = low.lowest(cover: nil)
            if partnerChoices.low != nil {
                leads.append(LeadPlan(position: position, lead: low, intent: .playLow))
            }
            if let partnerWinner = partnerChoices.win {
                leads.append(LeadPlan(position: position, lead: low, intent: .cashWinner, minThirdHand: partnerWinner))
            }
        }
        if let midChoices = choices.mid {
            for midChoice in midChoices {
                generateFinesses(position: position, leadRange: midChoice, partnerChoices: partnerChoices)
                generateRides(position: position, leadRange: midChoice, partnerChoices: partnerChoices)
            }
        }
        if let win = choices.win {
            leads.append(LeadPlan(position: position, lead: win, intent: .cashWinner))
        }
    }
    

}
