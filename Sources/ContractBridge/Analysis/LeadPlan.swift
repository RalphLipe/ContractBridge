//
//  LeadPlan.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



public struct LeadPlan: Equatable, Hashable {
    public let position: Position
    public let intent: Intent
    let lead: RankRange
    let minThirdHand: RankRange?
    let maxThirdHand: RankRange?
    
    public enum Intent {
        case cashWinner, // May lead a winner rank, or lead low rank with minThirdHand set to winner rank
             finesse,   // Always a lower rank lead toward a minThirdHand, with possible maxThirdHand
             ride,      // Always a mid-tier card.  May have maxThirdHand.  Never has minThirdHand.
             playLow    // Low card lead toward low card
    }
    
    init(position: Position, lead: RankRange, intent: Intent, minThirdHand: RankRange? = nil, maxThirdHand: RankRange? = nil) {
        self.position = position
        self.intent = intent
        self.lead = lead
        self.minThirdHand = minThirdHand
        self.maxThirdHand = maxThirdHand
    }
}


public extension String.StringInterpolation {
    private func ranks(range: ClosedRange<Rank>?, position: Position, hands: Hands?, suit: Suit?, style: ContractBridge.Style) -> String? {
        guard let range = range else { return nil }
        guard let hands = hands,
              let suit = suit else {
            return "\(range)"
        }
        // TODO: This is a kludge...
        var r = hands[position].ranks(for: suit)
        let rg = RankSet(range)
        r.formIntersection(rg)
        return "\(r, style: style)"
    }
    
    mutating func appendInterpolation(_ leadPlan: LeadPlan, hands: Hands? = nil, suit: Suit? = nil, style: ContractBridge.Style = .symbol) {
        let position = leadPlan.position
        let leadRanks = ranks(range: leadPlan.lead, position: leadPlan.position, hands: hands, suit: suit, style: style)!
        let minThirdRanks = ranks(range: leadPlan.minThirdHand,position: position.partner, hands: hands, suit: suit, style: style)
        let maxThirdRanks = ranks(range: leadPlan.maxThirdHand, position: position.partner, hands: hands, suit: suit, style: style)

        var desc: String = ""
        switch leadPlan.intent {
        case .cashWinner:
            if let minThirdRanks = minThirdRanks {
                desc = "lead \(leadRanks) from \(position, style: style) cashing winner \(minThirdRanks) "
            } else {
                desc = "cash winner \(leadRanks) in \(position, style: style)"
            }
        case .finesse:
            desc = "lead \(leadRanks) from \(position, style: style) finessing \(minThirdRanks!) "
            /*
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
             */ // TODO: Should we do this cover/not cover tingine
                
        case .ride:
            desc = "ride \(leadRanks) from \(position, style: style) "
            if let maxThirdRanks = maxThirdRanks {
                desc += "covering with \(maxThirdRanks)"
            } else {
                desc += "not covering"
            }
            
        case .playLow:
            desc = "play low \(leadRanks) from \(position, style: style)"
        }
        appendLiteral(desc)
    }
    
}
