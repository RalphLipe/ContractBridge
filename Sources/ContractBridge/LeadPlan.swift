//
//  LeadPlan.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation






public struct LeadPlan: CustomStringConvertible {
    let position: Position
    let rankRange: CountedCardRange
    let intent: Intent
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
            desc += "\(rankRange) "
            if let maxCover = self.maxThirdHand {
                desc += "covering with \(maxCover)"
            } else {
                desc += "not covering"
            }
        case .playLow:
            desc += "\(rankRange)"
        }
        return desc
    }
    
}



public class LeadAnalysis {
    private struct DealInfo {
        let id: Int
        let combinations: Int
    }
    
    public struct LeadStatistics {
        public let lead: LeadPlan
        let index: Int
        public let totalCombinations: Int
        public let maxTrickCombinations: [Int]
        
        public var maxTricks: Int { return maxTrickCombinations.count }
        public func combinationsFor(_ desiredTricks: Int) -> Int {
            var c = 0
            var i = desiredTricks - 1
            while i < self.maxTrickCombinations.endIndex {
                c += self.maxTrickCombinations[i]
                i += 1
            }
            return c
        }
        public func percentageFor(_ desiredTricks: Int) -> Double {
            let c = self.combinationsFor(desiredTricks)
            return Double(c) / Double(self.totalCombinations) * 100.0
        }
    }
    
    public let leads: [LeadPlan]
    public let worstCaseTricks: Int
    private var deals: [DealInfo]
    private var maxTricks: [[Int]]
    public internal(set) var combinations: Int
   
    init(leads: [LeadPlan], worstCase: Int) {
        self.leads = leads
        self.worstCaseTricks = worstCase
        self.deals = []
        self.maxTricks = Array<[Int]>(repeating: [], count: leads.count)
        self.combinations = 0
    }
    
    func recordResults(_ results: [Int], dealId: Int, combinations: Int) -> Void {
        assert(results.count == self.leads.count)
        assert(self.maxTricks.count == results.count)
        assert(self.maxTricks[0].count == self.deals.count)
        self.combinations += combinations
        deals.append(DealInfo(id: dealId, combinations: combinations))
        for i in results.indices {
            self.maxTricks[i].append(results[i])
        }
    }
    
    private func statsFor(leadIndex: Int) -> LeadStatistics {
        let maxTricks = self.maxTricks[leadIndex].reduce(0) { max($0, $1) }
        var trickCombinations = Array<Int>(repeating: 0, count: maxTricks)
        assert(self.deals.count == self.maxTricks[leadIndex].count)
        for d in deals.indices {
            let tricksThisDeal = self.maxTricks[leadIndex][d]
            trickCombinations[tricksThisDeal - 1] += self.deals[d].combinations
        }
        return LeadStatistics(lead: self.leads[leadIndex], index: leadIndex, totalCombinations: self.combinations, maxTrickCombinations: trickCombinations)
    }
    
    public func leadStatistics() -> [LeadStatistics] {
        var stats: [LeadStatistics] = []
        for i in self.leads.indices {
            stats.append(self.statsFor(leadIndex: i))
        }
        let maxTricks = stats.reduce(0) { max($1.maxTricks, $0) }
        stats.sort(by: { $0.combinationsFor(maxTricks) > $1.combinationsFor(maxTricks) })
        return stats
    }
}
