//
//  LeadPlan.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



public struct LeadPlan {
    public let position: Position
    public let intent: Intent
    public let leadRange: ClosedRange<Rank>
    public let minThirdHandRange: ClosedRange<Rank>?
    public let maxThirdHandRange: ClosedRange<Rank>?
    let lead: RankRange
    let minThirdHand: RankRange?
    let maxThirdHand: RankRange?
    
    public enum Intent {
        case cashWinner, // May lead a winner rank, or lead low rank with minThirdHand set to winner rank
             finesse,   // Always a lower rank lead toward a minThirdHand, with possible maxThirdHand
             ride,      // Always a mid-tier card.  May have maxThirdHand.  Never has minThirdHand.
             playLow    // Low card lead toward low card
    }
    
    init(position: Position, lead: CompositeRankRange, intent: Intent, minThirdHand: CompositeRankRange? = nil, maxThirdHand: CompositeRankRange? = nil) {
        self.position = position
        self.intent = intent
        self.lead = lead.lowest()
        self.minThirdHand = minThirdHand?.lowest()
        self.maxThirdHand = maxThirdHand?.lowest()
        self.leadRange = lead.range
        self.minThirdHandRange = minThirdHand?.range
        self.maxThirdHandRange = maxThirdHand?.range
    }
}


public extension String.StringInterpolation {
    private func ranks(range: ClosedRange<Rank>?, position: Position, hands: Hands?, suit: Suit?, style: ContractBridge.Style) -> String? {
        guard let range = range else { return nil }
        guard let hands = hands,
              let suit = suit else {
            return "\(range)"
        }
        return "\(hands[position].ranks(for: suit).intersection(range), style: style)"
    }
    
    mutating func appendInterpolation(_ leadPlan: LeadPlan, hands: Hands? = nil, suit: Suit? = nil, style: ContractBridge.Style = .symbol) {
        let position = leadPlan.position
        let leadRanks = ranks(range: leadPlan.leadRange, position: leadPlan.position, hands: hands, suit: suit, style: style)!
        let minThirdRanks = ranks(range: leadPlan.minThirdHandRange,position: position.partner, hands: hands, suit: suit, style: style)
        let maxThirdRanks = ranks(range: leadPlan.maxThirdHandRange, position: position.partner, hands: hands, suit: suit, style: style)

        var desc: String = ""
        switch leadPlan.intent {
        case .cashWinner:
            if let minThirdRanks = minThirdRanks {
                desc = "lead \(leadRanks) from \(position) cashing winner \(minThirdRanks) "
            } else {
                desc = "cash winner \(leadRanks) in \(position)"
            }
        case .finesse:
            desc = "lead \(leadRanks) from \(position) finessing \(minThirdRanks!) "
            /*
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
             */ // TODO: Should we do this cover/not cover tingine
                
        case .ride:
            desc = "ride \(leadRanks) from \(position) "
            if let maxThirdRanks = maxThirdRanks {
                desc += "covering with \(maxThirdRanks)"
            } else {
                desc += "not covering"
            }
            
        case .playLow:
            desc = "play low \(leadRanks) from \(position)"
        }
        appendLiteral(desc)
    }
    
}
