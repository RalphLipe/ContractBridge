//
//  LeadGenerator.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import Foundation



struct LeadGenerator {
    private let suitHolding: SuitHolding
    private let pair: Pair
    private var leads: [LeadPlan]

    private init(suitHolding: SuitHolding, pair: Pair) {
        self.suitHolding = suitHolding
        self.pair = pair
        self.leads = []
    }

    public static func generateLeads(suitHolding: SuitHolding, pair: Pair) -> [LeadPlan] {
       var generator = LeadGenerator(suitHolding: suitHolding, pair: pair)
        generator.generateLeads()
        return generator.leads
    }

    private mutating func generateLeads() {
        let choices0 = suitHolding.choices(pair.positions.0)
        let choices1 = suitHolding.choices(pair.positions.1)
        generateLeads(choices: choices0, partnerChoices: choices1)
        generateLeads(choices: choices1, partnerChoices: choices0)
    }
    
    
    private func coverRanges(cover: CompositeRankRange, coverChoices: ArraySlice<CompositeRankRange>) -> [CompositeRankRange?] {
        var ranges = Array<CompositeRankRange?>()
        var lastRange = cover
        var mustCover: CompositeRankRange? = nil
        // Starting with the first range and moving up, if the next range has a gap of one card
        // then we will always cover it, so we don't want to generate an uncovered finesse.
        for coverChoice in coverChoices {
            if coverChoice.range.lowerBound.nextLower != lastRange.range.upperBound.nextHigher {
                // Gap of > 1 card, so add this to the list (could be nil if first range has gap)
                ranges.append(mustCover)
            }
            mustCover = coverChoice
            lastRange = coverChoice
        }
        ranges.append(mustCover)
        return ranges
    }
    
    private mutating func generateFinesses(position: Position, leadRange: CompositeRankRange, partnerChoices: RangeChoices)  {
        for i in partnerChoices.all.indices {
            let finesseRange = partnerChoices.all[i]
            if leadRange < finesseRange &&
                finesseRange.isWinner == false {
                let coverRanges = i == partnerChoices.all.endIndex ? [nil] : coverRanges(cover: finesseRange, coverChoices: partnerChoices.all[(i + 1)...])
                for coverRange in coverRanges {
                    leads.append(LeadPlan(position: position, lead: leadRange, intent: .finesse, minThirdHand: finesseRange, maxThirdHand: coverRange))
                }
            }
        }
    }

    private mutating func generateRides(position: Position, leadRange: CompositeRankRange, partnerChoices: RangeChoices)  {
        var didSomething = false
        for i in partnerChoices.all.indices {
            if leadRange < partnerChoices.all[i] {
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
