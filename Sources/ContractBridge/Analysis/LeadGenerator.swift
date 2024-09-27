//
//  LeadGenerator.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation

public struct RangeChoices {
    // TODO: Is this "position" a good idea?
    public let position: Direction
    public let all: [Rank]
    public let win: Rank?
    public let mid: [Rank]?
    public let low: Rank?
    public let losingRank: Rank
    
    init(_ ranks: [Rank], position: Direction, loserUpperBound: Rank) {
        self.losingRank = loserUpperBound
        self.all = ranks
        self.position = position
        var r = all
        // It is important to look at the ranges in this order: Win, Low and then the rest
        // because when the final range is 2...A the last AND first are both winners and low
        self.win = r.count > 0 && r.last == .ace ? r.removeLast() : nil
        self.low = r.count > 0 && r.first == loserUpperBound ? r.removeFirst() : nil
        self.mid = r.count > 0 ? r : nil

    }
    init(holding: VariableRankPositions, position: Direction) {
        // TODO: Maybe just use rank set directly instead of arrays here.  But later on...
        self.init(Array<Rank>(holding.ranks(for: position)), position: position, loserUpperBound: holding.loserUpperBound)
    }
}


public enum LeadOption {
    case considerAll, leadHigh
}

public struct LeadGenerator {
    private let holding: VariableRankPositions
    private let pair: PairDirection
    private var leads: [LeadPlan]
    private let option: LeadOption

    private init(holding: VariableRankPositions, pair: PairDirection, option: LeadOption) {
        self.holding = holding
        self.pair = pair
        self.leads = []
        self.option = option
    }

    public static func generateLeads(holding: VariableRankPositions, pair: PairDirection, option: LeadOption) -> [LeadPlan] {
        var generator = LeadGenerator(holding: holding, pair: pair, option: option)
        generator.generateLeads()
        return generator.leads
    }

    private mutating func generateLeads() {
        let choices0 = RangeChoices(holding: holding, position: pair.directions.0)
        let choices1 = RangeChoices(holding: holding, position: pair.directions.1)
        if option == .leadHigh {
            let shortSide0 = holding.count(for: pair.directions.0) < holding.count(for: pair.directions.1)
            if (!generateHighLead(choices: choices0, partnerChoices: choices1, isShortSide: shortSide0)) {
                _ = generateHighLead(choices: choices1, partnerChoices: choices0, isShortSide: !shortSide0)
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
                    let max = choices.all.last!
                    let maxPartner = partnerChoices.all.last!
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
    
    // THIS IS WHERE I STOPPED FOR THE NIGHT.  THIS IS STRANGE SINCE IT CAN RETURN [NIL] FOR
    // uncovered finesse or ride logic.  Not sure if that's exactly what we want.
    // TODO:  THIS IS TOTALLY SCREWED UP.  FOR NOW COVER EVERYTHING AND ALWAYS RETURN [NIL]
    // TO MAKE UNCOVERED CHOICE TOO...
    private func cover(_ coverRank: Rank, coverChoices: ArraySlice<Rank>) -> [Rank?] {
        var ranks = Array<Rank?>()
        ranks.append(nil)
        coverChoices.forEach { ranks.append($0) }
        return ranks
        /*
        var ranks = Array<Rank?>()
        var lastRank = coverRank
        var mustCover: Rank? = nil
        // Starting with the first range and moving up, if the next range has a gap of one card
        // then we will always cover it, so we don't want to generate an uncovered finesse.
        // **** TODO: Make sure this logic still is right...
        for coverChoice in coverChoices {
            // TODO: Figure out if there is a single value gap.  If so then ........... what?
            if coverChoice.lowerBound.nextLower != lastRange.upperBound.nextHigher {
                // Gap of > 1 card, so add this to the list (could be nil if first range has gap)
                ranks.append(mustCover)
            }
            mustCover = coverChoice
            lastRank = coverChoice
        }
        ranks.append(mustCover)
        return ranks
         */
    }
    
    private mutating func generateFinesses(position: Direction, leadRank: Rank, partnerChoices: RangeChoices)  {
        for i in partnerChoices.all.indices {
            let finesseRank = partnerChoices.all[i]
            if leadRank < finesseRank && finesseRank < .ace {
                let coverRanks = i == partnerChoices.all.endIndex ? [nil] : cover(finesseRank, coverChoices: partnerChoices.all[(i + 1)...])
                for coverRank in coverRanks {
                    leads.append(LeadPlan(position: position, lead: leadRank, intent: .finesse, minThirdHand: finesseRank, maxThirdHand: coverRank))
                }
            }
        }
    }

    private mutating func generateRides(position: Direction, leadRank: Rank, partnerChoices: RangeChoices)  {
        var didSomething = false
        for i in partnerChoices.all.indices {
            if leadRank < partnerChoices.all[i] {
                let coverRanks = cover(leadRank, coverChoices: partnerChoices.all[i...])
                for coverRank in coverRanks {
                    leads.append(LeadPlan(position: position, lead: leadRank, intent: .ride, minThirdHand: nil, maxThirdHand: coverRank))
                    didSomething = true
                    
                }
                break
            }
        }
        if !didSomething {
            leads.append(LeadPlan(position: position, lead: leadRank, intent: .ride, minThirdHand: nil, maxThirdHand: nil))
        }
    }
    
    


    private mutating func generateLeads(choices: RangeChoices, partnerChoices: RangeChoices) {
        if choices.all.count == 0 {
            return
        }
        let position = choices.position
        if partnerChoices.all.count == 0 {
            // Simply try the highest and lowest as choices.  If highest is .ace then
            // it's a winner.  If they the same rank then just do the one thing...
            let high = choices.all.last!
            let low = choices.all.first!
            if high == low {
                let intent: LeadPlan.Intent = high == .ace ? .cashWinner : high == choices.losingRank ? .playLow : .ride
                leads.append(LeadPlan(position: position, lead: high, intent: intent))
                return
            }
            leads.append(LeadPlan(position: position, lead: high, intent: high == .ace ? .cashWinner : .ride))
            leads.append(LeadPlan(position: position, lead: low, intent: low == choices.losingRank ? .playLow : .ride))
            return
        }
        // TODO: Perhaps if next position shows out then we could avoid generating some of these leads.
        generateFinesses(position: position, leadRank: choices.all[0], partnerChoices: partnerChoices)
        if let low = choices.low {
        // TODO:  Both of the following are symetrical -- don't do it again.  Just replicate it
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
                generateRides(position: position, leadRank: midChoice, partnerChoices: partnerChoices)
            }
        }
        if let win = choices.win {
            leads.append(LeadPlan(position: position, lead: win, intent: .cashWinner))
        }
    }
    

}
