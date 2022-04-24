//
//  LeadPlan.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



public struct LeadPlan: CustomStringConvertible {
    public let position: Position
    let rankRange: CountedCardRange
    public let intent: Intent
    let minThirdHand: CountedCardRange?
    let maxThirdHand: CountedCardRange?
    
    public enum Intent {
        case cashWinner, // May lead a winner rank, or lead low rank with minThirdHand set to winner rank
             finesse,   // Always a lower rank lead toward a minThirdHand, with possible maxThirdHand
             ride,      // Always a mid-tier card.  May have maxThirdHand.  Never has minThirdHand.
             playLow    // Low card lead toward low card
    }
    
    init(position: Position, rankRange: CountedCardRange, intent: Intent, minThirdHand: CountedCardRange? = nil, maxThirdHand: CountedCardRange? = nil) {
        self.position = position
        self.rankRange = rankRange
        self.intent = intent
        self.minThirdHand = minThirdHand
        self.maxThirdHand = maxThirdHand
    }
    
    public var description: String {
        var desc = "\(self.intent) "
        switch self.intent {
        case .cashWinner:
            if let thirdHandWinner = minThirdHand {
                desc += "lead \(rankRange) toward \(thirdHandWinner)"
            } else {
                desc += "\(rankRange)"
            }
        case .finesse:
            desc += "lead \(rankRange) from \(position) finessing \(minThirdHand!) "
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
                
        case .ride:
            desc += "\(rankRange) from \(position) "
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
        case .playLow:
            desc += "\(rankRange) from \(position)"
        }
        return desc
    }
    
}
