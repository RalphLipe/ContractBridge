//
//  LeadAnalysis.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public struct LeadAnalysis: Comparable {
    public static func < (lhs: LeadAnalysis, rhs: LeadAnalysis) -> Bool {
        return lhs.stats < rhs.stats
    }
    
    public let stats: LeadStatistics
    public let play: PositionRanks
}

public struct LeadAnalyzer {
    public let holding: VariableCombination
    public let requiredTricks: Int
    public let leadPlan: LeadPlan
 //   public internal(set) var winner: Position
    public internal(set) var play = PositionRanks()
    public internal(set) var stats = LeadStatistics()
    private var nextToAct: Position
    private var positionsPlayed = 0
    private let leadOption: LeadOption
    private let cache: StatsCache?
    
    public var analysis: LeadAnalysis {
        return LeadAnalysis(stats: stats, play: play)
    }
    
 //   public var winningRank: Rank { return analysis.play[winner]! }

 /*
    public static func doubleDummy(holding: VariableCombination, leadPlan: LeadPlan, leadOption: LeadOption) -> LeadAnalysis {
        return LeadAnalyzer(holding: holding, leadPlan: leadPlan, requiredTricks: 0, leadOption: leadOption).analysis
    }
  */
    public static func statistical(holding: VariableCombination, leadPlan: LeadPlan, requiredTricks: Int, leadOption: LeadOption, cache: StatsCache?) -> LeadAnalysis {
        return LeadAnalyzer(holding: holding, leadPlan: leadPlan, requiredTricks: requiredTricks, leadOption: leadOption, cache: cache).analysis
    }
    
 
    private init(holding: VariableCombination, leadPlan: LeadPlan, requiredTricks: Int, leadOption: LeadOption, cache: StatsCache?) {
        self.holding = holding
        self.cache = cache
        self.leadPlan = leadPlan
        self.requiredTricks = requiredTricks
        self.leadOption = leadOption
        self.play[leadPlan.position] = leadPlan.lead
        self.positionsPlayed = 1
        self.nextToAct = leadPlan.position.next
        stats = playNextPosition()

    }
    
    mutating func play(_ playedRank: Rank?) -> LeadStatistics {
        let currentPosition = nextToAct
//        let currentWinner = winner
        positionsPlayed += 1
        play[currentPosition] = playedRank
        self.nextToAct = self.nextToAct.next
 //       if playedRank != nil && playedRank! > self.winningRank {
 //           winner = currentPosition
 //       }
        let stats = (positionsPlayed == 4) ? analyzeNextHolding() : playNextPosition()
        play[currentPosition] = nil
        nextToAct = currentPosition
 //       winner = currentWinner
        positionsPlayed -= 1
        return stats
    }
    
    internal func analyzeNextHolding() -> LeadStatistics {
        let nextVC = holding.play(leadPosition: leadPlan.position, play: play)
        let nextHolding = VariableHolding(from: nextVC)
        let wonTrick = play.winning?.position.pair == leadPlan.position.pair
        let nextRequiredTricks = wonTrick ? max(0, requiredTricks - 1) : requiredTricks
        if nextHolding.holdsRanks(leadPlan.position.pair) {
            // TODO: Perhaps handle trivial cases here....
            // WHAT WE NEED TO DO:
            //   Get the nextHolding AND variableCombination
            let nextSA = StatisticalAnalysis.analyze(holding: nextHolding, leadPair: leadPlan.position.pair, requiredTricks: nextRequiredTricks, leadOption: leadOption, cache: cache)
            // TODO: This is not efficient... Add to Statistical Analyis
            let allLeadStats = nextSA.leadAnalyses(for: nextVC)
            let bestLeads = nextSA.bestLeads
            let stats = allLeadStats[bestLeads.first!]!.stats
            if wonTrick {
                return LeadStatistics(averageTricks: stats.averageTricks + 1.0, percentMaking: stats.percentMaking)
                
            }
            return stats
        }
  //      if !wonTrick {
  //          print("Well we dont win everything!")
  //      }
        return LeadStatistics(averageTricks: wonTrick ? 1.0 : 0.0, percentMaking: nextRequiredTricks == 0 ? 100.0 : 0.0)
    }

    // TODO: Work on this --- There are bugs
    func handleTrivialCases(nextHolding: RankPositions, tricksWon: inout Int) -> Bool {
        /*
        let leadPair = leadPlan.position.pair
        let positions = leadPair.positions
        let remainingTricks = max(nextHolding.count(for: positions.0), nextHolding.count(for: positions.1))
        assert(remainingTricks > 0)
        var neededTricks = remainingTricks
        var winningPair: Pair? = nil
        for rank in Rank.allCases.reversed() {
            if let rankPos = nextHolding[rank] {
                if rankPos.pair == leadPair {   // lead pair wins this one
                    if winningPair == nil || winningPair! == leadPair {
                        winningPair = leadPair
                        neededTricks -= 1
                    } else {
                        return false
                    }
                } else {
                    assert(rankPos.pair == leadPair.opponents)
                    if winningPair == nil || winningPair! == leadPair.opponents {
                        winningPair = leadPair.opponents
                        neededTricks -= 1
                    } else {
                        return false
                    }
                }
                if neededTricks == 0 {
                    if winningPair! == leadPair { tricksWon += remainingTricks }
                    return true
                }
            }
        }
        // TODO: Any possible way to get here???
         */
        return false
    }
    
    mutating func playNextPosition() -> LeadStatistics {
        assert(positionsPlayed < 4)
        let hand = holding.ranks(for: nextToAct)
        var rank: Rank? = nil
        if hand.count <= 1 {
            rank = hand.min()
        } else {
            switch positionsPlayed {
            case 1:
                rank = secondHand(hand: hand)
            case 2:
                rank = thirdHand(hand: hand)
            case 3:
                rank = fourthHand(hand: hand)
            default:
                fatalError()
            }
        }
        
        return play(rank)
    }

    // This function will only be called if there are two or more cards
    private mutating func secondHand(hand: RankSet) -> Rank {
        assert(hand.count > 1)
        var lowestTrickRank = hand.min()!   // This is "2nd hand low" which we will always analyze as a choice
        if leadPlan.intent == .cashWinner { return lowestTrickRank }

        var lowestTrickCount = play(lowestTrickRank)
        // We will only consider other, higher choices if they are:
        //  Higher than 2nd hand's lowest card
        //  Higher than the lead rank (the current winning rank)
        //  Higher than any minimum play at 3rd hand (usually a finesse)
        //  or if no required 3rd hand then at least higher than 3rd hand's lowest rank
        var minConsiderRank = max(leadPlan.lead, lowestTrickRank)
        if let minThirdHand = leadPlan.minThirdHand {
            // TODO: Need to reqork this stuff...
            minConsiderRank = max(minConsiderRank, minThirdHand)
        } else {
            let thirdHand = holding.ranks(for: nextToAct.next)
            if thirdHand.count > 0 {
                minConsiderRank = max(minConsiderRank, thirdHand.min()!)
            }
        }
        for choice in hand {
            // Only consider a high play if the rank is higher than the lead rank, and if
            // there is a minimum 3rd hand value, if the high play would be higher than the
            // minimum 3rd hand play (normally a finesse)
            if choice >= minConsiderRank {
                let maxTricks = play(choice)
                if lowestTrickCount > maxTricks {
                    lowestTrickRank = choice
                    lowestTrickCount = maxTricks
                }
            }
        }
        return lowestTrickRank
    }
    
    private func thirdHand(hand: RankSet) -> Rank {
        assert(nextToAct.pair == .ns)
        var cover: Rank? = nil
        guard let winning = play.winning else { fatalError("There must be at least one winning rank") }
        if let min = leadPlan.minThirdHand,
           winning.position.pair == leadPlan.position.pair || min > winning.rank {
            cover = min
        }
        if cover == nil && winning.position.pair == leadPlan.position.pair.opponents {
            if let maxThirdHand = leadPlan.maxThirdHand,
               maxThirdHand > winning.rank {
                cover = winning.rank
            }
        }
        return hand.min(atLeast: cover)!
    }
    
    private func fourthHand(hand: RankSet) -> Rank {
        guard let winning = play.winning else { fatalError("There must be at least one winning rank") }
        let rankToCover = winning.position.pair == leadPlan.position.pair ? winning.rank : nil
        return hand.min(atLeast: rankToCover)!
    }
}

