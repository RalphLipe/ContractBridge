//
//  CardCombinationAnalyzer.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//


public class CardCombinationAnalyzer {
    var suitHolding: SuitHolding { return layoutAnalyzer.suitHolding }
    var tricks: [Trick] = []
    var showsOut: Set<Position> = []
    var layoutAnalyzer: LayoutAnalyzer
    var recordCombinationStatistics = true
    

    class Trick {
        let leadPlan: LeadPlan
        var ranks: [Position:RankRange] = [:]
        var winningPosition: Position
        let recordFinalPlay: Bool
        var finalPlay: TrickSequence? = nil
        public private(set) var positionsPlayed: Int
        public private(set) var nextToAct: Position
        var winningRankRange: RankRange { ranks[self.winningPosition]! }
        var leadRankRange: RankRange { ranks[self.leadPlan.position]! }
        
        init(lead: LeadPlan, recordFinalPlay: Bool = false) {
            self.leadPlan = lead
            self.nextToAct = lead.position.next
            self.ranks[lead.position] = lead.lead
            self.winningPosition = lead.position
            self.positionsPlayed = 1
            self.recordFinalPlay = recordFinalPlay
        }
        
        func play(_ rankRange: RankRange?, nextStep: (Trick) -> Int) -> Int {
            let currentPosition = nextToAct
            let currentWinningPosition = winningPosition
            positionsPlayed += 1
            ranks[currentPosition] = rankRange
            self.nextToAct = self.nextToAct.next
            if let rankRange = rankRange {
                if rankRange > self.winningRankRange { self.winningPosition = currentPosition }
            }
            var playedRanks: [Position:Rank]? = nil
            if positionsPlayed == 4 {
                playedRanks = [:]
                for position in Position.allCases {
                    if let rankRange = ranks[position] {
                        playedRanks![position] = rankRange.play()
                    }
                }
            }
            let maxTricks = nextStep(self)
            if let playedRanks = playedRanks {
                for position in Position.allCases {
                    if let rank = playedRanks[position] {
                        ranks[position]!.undoPlay(rank: rank)
                    }
                }
                // Make sure the final play is recoreded AFTER the cards have been "un-played" since
                // the TrickSequence logic will attempt to find ranges of equal cards...
                if recordFinalPlay {
                    finalPlay = TrickSequence(winningPosition: winningPosition, play: ranks.mapValues { $0.promotedRange })
                }
            }
            self.ranks[currentPosition] = nil
            self.nextToAct = currentPosition
            self.winningPosition = currentWinningPosition
            self.positionsPlayed -= 1
            return maxTricks
        }
    }

    

    private init(suitHolding: SuitHolding) {
        self.layoutAnalyzer = LayoutAnalyzer(suitHolding: suitHolding, leads: LeadGenerator.generateLeads(suitHolding: suitHolding, pair: .ns))
        assert(layoutAnalyzer.leads.count > 0)

    }



    
    static public func analyze(suitHolding: SuitHolding) -> LayoutAnalysis {
        let workingHolding = SuitHolding(from: suitHolding)
        let cca = CardCombinationAnalyzer(suitHolding: workingHolding)
        cca.recordCombinationStatistics = false
        cca.recordLeadSequences()
        cca.recordCombinationStatistics = true
        cca.suitHolding.forAllCombinations(pair: .ew, cca.analyzeThisDeal)
        
        return cca.layoutAnalyzer.generateAnalysis()
    }
    

    internal func recordLeadSequences() -> Void {
        layoutAnalyzer.leads.forEach { leadAndRecordTrickSequence($0) }
    }


    private func analyzeThisDeal(combinations: Int) {
        assert(tricks.count == 0)
        let results = analyzeLeads(leads: self.layoutAnalyzer.leads)
        assert(layoutAnalyzer.leads.count == results.count)
        if recordCombinationStatistics {
            layoutAnalyzer.recordResults(results, layoutId: SuitLayout(suitHolding: suitHolding).id, combinations: combinations)
        }
    }
    




 
    func playNextPosition(trick: Trick) -> Int {
        if trick.positionsPlayed == 4 {
            return self.leadAgain()
        }
        let position = trick.nextToAct
        let hand = suitHolding[position]
        let numCards = hand.count
        var rank: RankRange? = nil
        if numCards == 1 {
            rank = hand.lowest(cover: nil)
        } else if numCards > 1 {
            switch trick.positionsPlayed {
            case 1:
                rank = secondHand(trick: trick, hand: hand)
            case 2:
                rank = thirdHand(trick: trick, hand: hand)
            case 3:
                rank = fourthHand(trick: trick, hand: hand)
            default:
                fatalError()
            }
        }
        
        let maxTricks: Int
        if let rank = rank {
            maxTricks = trick.play(rank, nextStep: self.playNextPosition)
        } else {
            if position.pair == .ew {
                let hadShownOut = self.showsOut.contains(position)
                self.showsOut.insert(position)
                maxTricks = trick.play(nil, nextStep: self.playNextPosition)
                if !hadShownOut { self.showsOut.remove(position) }
            } else {
                maxTricks = trick.play(nil, nextStep: self.playNextPosition)
            }
        }
        return maxTricks
    }

    // This function will only be called if there are two or more cards
    private func secondHand(trick: Trick, hand: CompositeRankRange) -> RankRange {
        if trick.leadPlan.intent == .cashWinner { return hand.lowest(cover: nil) }
        
        let position = trick.nextToAct
        // Simplest case is that we have only one real choice of cards in this hand.  Just return a card now
        var lowestTrickRank = hand.lowest()     // This is "2nd hand low" which we will always analyze as a choice
        let ourChoices = suitHolding.choices(position)
        if ourChoices.all.count > 1 {
            var lowestTrickCount = trick.play(lowestTrickRank, nextStep: playNextPosition)
            // We will only consider other, higher choices if they are:
            //  Higher than 2nd hand's lowest card
            //  Higher than the lead rank (the current winning rank)
            //  Higher than any minimum play at 3rd hand (usually a finesse)
            //  or if no required 3rd hand then at least higher than 3rd hand's lowest rank
            var minConsiderRank = max(trick.leadPlan.lead, lowestTrickRank)
            if let minThirdHand = trick.leadPlan.minThirdHand {
                minConsiderRank = max(minConsiderRank, minThirdHand)
            } else {
                let thirdHand = suitHolding[position.next]
                if thirdHand.count > 0 {
                    minConsiderRank = max(minConsiderRank, thirdHand.lowest())
                }
            }
            for choice in ourChoices.all {
                // Only consider a high play if the rank is higher than the lead rank, and if
                // there is a minimum 3rd hand value, if the high play would be higher than the
                // minimum 3rd hand play (normally a finesse)
                if choice.range.lowerBound > minConsiderRank.range.upperBound {
                    let rankRange = choice.lowest(cover: nil)
                    let maxTricks = trick.play(rankRange, nextStep: playNextPosition)
                    if lowestTrickCount > maxTricks {
                        lowestTrickRank = rankRange
                        lowestTrickCount = maxTricks
                    }
                }
            }
        }
        return lowestTrickRank
    }
    
    private func thirdHand(trick: Trick, hand: CompositeRankRange) -> RankRange {
        assert(trick.nextToAct.pair == .ns)
        var cover: RankRange? = nil
        if let min = trick.leadPlan.minThirdHand,
           trick.winningPosition.pair == .ns || min > trick.winningRankRange {
            cover = min
        }
        if cover == nil && trick.winningPosition.pair == .ew {
            if let maxThirdHand = trick.leadPlan.maxThirdHand,
               maxThirdHand > trick.winningRankRange {
                cover = trick.winningRankRange
            }
        }
        return hand.lowest(cover: cover)
    }
    
    
    private func fourthHand(trick: Trick, hand: CompositeRankRange) -> RankRange {
        let rankToCover = trick.winningPosition.pair == .ns ? trick.winningRankRange : nil
        return hand.lowest(cover: rankToCover)
    }
    

    
    private func lead(_ lead: LeadPlan) -> Int {
        let trick = Trick(lead: lead)
        self.tricks.append(trick)
        let maxTricks = self.playNextPosition(trick: trick)
        _ = self.tricks.removeLast()
        return maxTricks
    }
    
    private func leadAndRecordTrickSequence(_ lead: LeadPlan) -> Void {
        assert(tricks.count == 0)
        let trick = Trick(lead: lead, recordFinalPlay: true)
        tricks.append(trick)
        let maxTricks = self.playNextPosition(trick: trick)
        _ = self.tricks.removeLast()
        layoutAnalyzer.recordTrickSequence(trick.finalPlay!, maxTricks: maxTricks)
    }
    
    
    private func leadAgain() -> Int {
        if suitHolding[.north].count > 0 || suitHolding[.south].count > 0 {
            return analyzeLeads(leads: LeadGenerator.generateLeads(suitHolding: suitHolding, pair: .ns)).reduce(0) { $1 > $0 ? $1 : $0 }
        } else {
            return tricks.reduce(0) { return $1.winningPosition.pair == .ns ? $0 + 1 : $0 }
        }
    }
    
    private func analyzeLeads(leads: [LeadPlan]) -> [Int] {
        return leads.map { lead($0) }
    }
    



}


