//
//  LeadAnalysis.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public struct LeadAnalysis: Comparable {
    public static func < (lhs: LeadAnalysis, rhs: LeadAnalysis) -> Bool {
        return lhs.tricksTaken < rhs.tricksTaken
    }
    
    public let tricksTaken: Int
    public let play: PositionRanks
    
    internal init(tricksTaken: Int, play: PositionRanks) {
        assert(tricksTaken < 14)
        self.tricksTaken = tricksTaken
        self.play = play
    }
    
    
    private func maxRank(for pair: Pair) -> Rank? {
        let positions = pair.positions
        if let play0 = play[positions.0] {
            if let play1 = play[positions.1] {
                return max(play0, play1)
            } else {
                return play0
            }
        } else {
            return play[positions.1]
        }
    }
    
    public var winningPair: Pair {
        guard let nsMax = maxRank(for: .ns) else { return .ew }
        guard let ewMax = maxRank(for: .ew) else { return .ns }
        return nsMax > ewMax ? .ns : .ew
    }
    
}

public struct LeadAnalyzer {
    public let holding: RankPositions
    public let requiredTricks: Int
    public let leadPlan: LeadPlan
    public internal(set) var winner: Position
    public internal(set) var playedRanges = Array<RankRange?>(repeating: nil, count: Position.allCases.count)
    public internal(set) var tricksTaken = 0

    // These values are only used during analysis and are not used later.
    // TODO: Should we have another struct thta tdoes thte analysis and return the result?
    private var nextToAct: Position
    public let marked: RankSet? // This only makes sense for non-double dummy...  Maybe this class can do both though
    private var positionsPlayed = 0
    private var inSecondHandDD = false
    private let leadOption: LeadOption

    
    public var winningRankRange: RankRange { return self[winner]! }
    private var statisticalAnalysis: Bool { return marked != nil }

    
    public private(set) subscript(position: Position) -> RankRange? {
        get {
            return playedRanges[position.rawValue]
        }
        set {
            playedRanges[position.rawValue] = newValue
        }
    }
    
    public var analysis: LeadAnalysis {
        var pr = PositionRanks()
        Position.allCases.forEach { pr[$0] = playedRanges[$0.rawValue]?.upperBound }    // TODO: Remove this hack
        return LeadAnalysis(tricksTaken: tricksTaken, play: pr)
    }
    
    public static func doubleDummy(holding: RankPositions, leadPlan: LeadPlan, leadOption: LeadOption) -> LeadAnalysis {
        return LeadAnalyzer(holding: holding, leadPlan: leadPlan, marked: nil, requiredTricks: 0, leadOption: leadOption).analysis
    }
    public static func statistical(holding: RankPositions, leadPlan: LeadPlan, marked: RankSet, requiredTricks: Int, leadOption: LeadOption) -> LeadAnalysis {
        return LeadAnalyzer(holding: holding, leadPlan: leadPlan, marked: marked, requiredTricks: requiredTricks, leadOption: leadOption).analysis
    }
    
 
    private init(holding: RankPositions, leadPlan: LeadPlan, marked: RankSet?, requiredTricks: Int, leadOption: LeadOption) {
        self.holding = holding
        self.leadPlan = leadPlan
        self.marked = marked
        self.requiredTricks = requiredTricks
        self.leadOption = leadOption
        self.winner = leadPlan.position
        self.playedRanges[winner.rawValue] = leadPlan.lead
        self.positionsPlayed = 1
        self.nextToAct = leadPlan.position.next
        tricksTaken = playNextPosition()
        if tricksTaken > 10 {
            print("FOOGOGOGO")
        }
        // At this point, winner will always be equal to the lead position (since it has been unwound)
        // compute the appropriate winner...
        // TODO: This is not really accurate...  The real "winner" will be in the same pair, but the one with
        // the higher minimum rank is the actual winner.  This may confuse clients.  One solution is to make
        // winner a private variable and possibly expose a property that returns the appropriate winner...
        var winningRank = leadPlan.lead
        var winningPos = leadPlan.position
        var pos = winningPos.next
        while pos != leadPlan.position {
            if let play = self[pos] {
                if play.upperBound > winningRank.upperBound {
                    winningRank = play
                    winningPos = pos
                }
    
            }
            pos = pos.next
            
        }
        winner = pos
    }
    
    mutating func play(_ playedRange: RankRange?) -> Int {
        let currentPosition = nextToAct
        let currentWinner = winner
        positionsPlayed += 1
        self[currentPosition] = playedRange
        self.nextToAct = self.nextToAct.next
        if playedRange != nil && playedRange!.upperBound > self.winningRankRange.upperBound {
            winner = currentPosition
        }
        let maxTricks = (positionsPlayed == 4) ? analyzeNextHolding() : playNextPosition()
        self[currentPosition] = nil // TODO: Is this necessary?  If so what does it do?
        nextToAct = currentPosition
        winner = currentWinner
        positionsPlayed -= 1
        return maxTricks
    }
    
    internal func analyzeNextHolding() -> Int {
        var nextHolding = holding
        var playedRanks = [Position: Rank]()        // TODO: This is stupid.  Get rid of it but used by hodling.mark
        for position in Position.allCases {
            if let rankRange = self[position] {
                playedRanks[position] = nextHolding.play(rankRange, from: position)
            }
        }
        var tricksWon = winner.pair == .ns ? 1 : 0
        if nextHolding.hasRanks(leadPlan.position.pair) {
            if handleTrivialCases(nextHolding: holding, tricksWon: &tricksWon) == false {
                if statisticalAnalysis && !inSecondHandDD {
                    let nextRequiredTricks = max(0, requiredTricks - tricksWon)
                  //  let nextMarked = holding.mark(knownMarked: marked!, leadFrom: leadPlan.position, play: playedRanks)
                    let nextMarked = marked!     // TODO: Remove this - it's bogus.
                    let nextSA = StatisticalAnalysis(holding: nextHolding, leadPair: leadPlan.position.pair, requiredTricks: nextRequiredTricks, marked: nextMarked, leadOption: leadOption)
                    tricksWon += nextSA.numTricksBestLeadInitialLayout
                } else {
                    let nextDDAZ = DoubleDummyAnalysis(holding: nextHolding, leadPair: leadPlan.position.pair)
                    tricksWon += nextDDAZ.maxTricksTaken
                }
            }
        }
        return tricksWon
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
    
    mutating func playNextPosition() -> Int {
        assert(positionsPlayed < 4)
        let hand = holding.playableRanges(for: nextToAct)
        var rank: RankRange? = nil
        if hand.count <= 1 {
            rank = hand.lowest()
        } else {
            switch positionsPlayed {
            case 1:
                inSecondHandDD = true
                rank = secondHand(hand: hand)
                inSecondHandDD = false
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

    private func higher(_ a: RankRange, _ b: RankRange) -> RankRange {
        return a.upperBound > b.upperBound ? a : b
    }
    
    // This function will only be called if there are two or more cards
    private mutating func secondHand(hand: [RankRange]) -> RankRange {
        assert(hand.count > 1)
        if leadPlan.intent == .cashWinner { return hand[0] }
        var lowestTrickRank = hand[0]   // This is "2nd hand low" which we will always analyze as a choice
        var lowestTrickCount = play(lowestTrickRank)
        // We will only consider other, higher choices if they are:
        //  Higher than 2nd hand's lowest card
        //  Higher than the lead rank (the current winning rank)
        //  Higher than any minimum play at 3rd hand (usually a finesse)
        //  or if no required 3rd hand then at least higher than 3rd hand's lowest rank
        var minConsiderRank = higher(leadPlan.lead, lowestTrickRank)
        if let minThirdHand = leadPlan.minThirdHand {
            // TODO: Need to reqork this stuff...
            minConsiderRank = higher(minConsiderRank, minThirdHand)
        } else {
            let thirdHand = holding.playableRanges(for: nextToAct.next)
            if thirdHand.count > 0 {
                minConsiderRank = higher(minConsiderRank, thirdHand.lowest()!)
            }
        }
        for choice in hand {
            // Only consider a high play if the rank is higher than the lead rank, and if
            // there is a minimum 3rd hand value, if the high play would be higher than the
            // minimum 3rd hand play (normally a finesse)
            if choice.upperBound >= minConsiderRank.upperBound {
                let maxTricks = play(choice)
                if lowestTrickCount > maxTricks {
                    lowestTrickRank = choice
                    lowestTrickCount = maxTricks
                }
            }
        }
        return lowestTrickRank
    }
    
    private func thirdHand(hand: [RankRange]) -> RankRange {
        assert(nextToAct.pair == .ns)
        var cover: RankRange? = nil
        if let min = leadPlan.minThirdHand,
            winner.pair == .ns || min.upperBound > winningRankRange.upperBound {
            cover = min
        }
        if cover == nil && winner.pair == .ew {
            if let maxThirdHand = leadPlan.maxThirdHand,
               maxThirdHand.upperBound > winningRankRange.upperBound {
                cover = winningRankRange
            }
        }
        return hand.lowest(coverIfPossible: cover)!
    }
    
    private func fourthHand(hand: [RankRange]) -> RankRange {
        let rankToCover = winner.pair == .ns ? winningRankRange : nil
        return hand.lowest(coverIfPossible: rankToCover)!
    }
}

