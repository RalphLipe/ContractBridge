//
//  LeadPlan.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



public struct LeadPlan: CustomStringConvertible {
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
    
    public var description: String {
        var desc: String = ""
        switch self.intent {
        case .cashWinner:
            if let thirdHandWinner = minThirdHandRange {
                desc = "lead \(leadRange) from \(position) cashing winner \(thirdHandWinner) "
            } else {
                desc = "cash winner \(leadRange) in \(position)"
            }
        case .finesse:
            desc = "lead \(leadRange) from \(position) finessing \(minThirdHandRange!) "
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
                
        case .ride:
            desc = "ride \(leadRange) from \(position) "
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
        case .playLow:
            desc = "play low \(leadRange) from \(position)"
        }
        return desc
    }
    
}
