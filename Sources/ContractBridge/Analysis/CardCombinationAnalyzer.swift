//
//  CardCombinationAnalyzer.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation



public class CardCombinationAnalyzer {
    var suitHolding: SuitHolding    // TODO: Should be a let but hack!!!
    var tricks: [Trick] = []
    var shortSide: Position? = nil
    var showsOut: Set<Position> = []
    var layoutAnalyzer: LayoutAnalyzer
    var recordCombinationStatistics = true
    let recordLayoutIds: Bool
    
    
    class Trick {
        let leadPlan: LeadPlan
        var ranks: [Position:CountedCardRange] = [:]
        var winningPosition: Position
        let recordFinalPlay: Bool
        var finalPlay: TrickSequence? = nil
        public private(set) var positionsPlayed: Int
        public private(set) var nextToAct: Position
        var winningRankRange: CountedCardRange { ranks[self.winningPosition]! }
        var leadRankRange: CountedCardRange { ranks[self.leadPlan.position]! }
        
        init(lead: LeadPlan, recordFinalPlay: Bool = false) {
            self.leadPlan = lead
            self.nextToAct = lead.position.next
            self.ranks[lead.position] = lead.rankRange
            self.winningPosition = lead.position
            self.positionsPlayed = 1
            self.recordFinalPlay = recordFinalPlay
        }
        
        func play(_ rankRange: CountedCardRange?, nextStep: (Trick) -> Int) -> Int {
            let currentPosition = nextToAct
            let currentWinningPosition = winningPosition
            positionsPlayed += 1
            ranks[currentPosition] = rankRange
            self.nextToAct = self.nextToAct.next
            if let rankRange = rankRange {
                if rankRange > self.winningRankRange { self.winningPosition = currentPosition }
            }
            if positionsPlayed == 4 {
                for range in self.ranks.values {
                    range.playCard(play: true)  // And then move it to the played hand
                }
            }
            let maxTricks = nextStep(self)
            if positionsPlayed == 4 {
                for range in self.ranks.values {
                    range.playCard(play: false)
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


    // TODO: Remvove this method...
    private func hand(_ position: Position) -> CompositeCardRange {
        return suitHolding[position]
    }

    

    

    private init(suitHolding: SuitHolding) {
        self.shortSide = .south     // BUGBUG: Fix this.  Wheere is it used
        self.suitHolding = suitHolding
        recordLayoutIds = suitHolding.isFullHolding
        
        let northCards = suitHolding[.north].toCards()
        let southCards = suitHolding[.south].toCards()
        let allNS = northCards + southCards
        let allEW = suitHolding[.east].toCards() + suitHolding[.west].toCards()
        
        var longestHand: Int
        if northCards.count < southCards.count {
            shortSide = .north
            longestHand = southCards.count
        } else if northCards.count > southCards.count {
            shortSide = .south
            longestHand = northCards.count
        } else {
            longestHand = northCards.count
        }
        
        let worstCaseTricks = CardCombinationAnalyzer.computeMinTricks(ns: allNS, ew: allEW, longestHand: longestHand)
        
        // Make the compiler happy by initializing these properties so "self" is valid before generating leads
        self.layoutAnalyzer = LayoutAnalyzer(suitLayoutId: suitHolding.initialLayout.id, leads: [], worstCase: worstCaseTricks)
        self.layoutAnalyzer = LayoutAnalyzer(suitLayoutId: suitHolding.initialLayout.id, leads: generateLeads(), worstCase: worstCaseTricks)

    }



    
    private class func computeMinTricks(ns: [Card], ew: [Card], longestHand: Int) -> Int {
        var nsCards = ns
        var ewCards = ew
        nsCards.sortHandOrder()
        ewCards.sortHandOrder()
        nsCards.removeLast(nsCards.count - longestHand)

        var minTricks = 0
        while ewCards.count > 0 && nsCards.count > 0 {
            let nsPlayed = nsCards.removeFirst()
            if nsPlayed > ewCards.first! {
                minTricks += 1
                _ = ewCards.removeLast()
            } else {
                _ = ewCards.removeFirst()
            }
        }
        minTricks += nsCards.count
        return minTricks
    }
    
    
    



    
    static public func analyze(suitHolding: SuitHolding) -> LayoutAnalysis {
        let workingHolding = SuitHolding(from: suitHolding, usePositionRanks: false)
        let cca = CardCombinationAnalyzer(suitHolding: workingHolding)
        cca.recordCombinationStatistics = false
        cca.recordLeadSequences()
        cca.recordCombinationStatistics = true
        workingHolding.movePairCardsTo(.east)
        cca.buildAllHandsAndAnalyze(moveIndex: 0, combinations: 1)

        return cca.layoutAnalyzer.generateAnalysis()
    }
    

    internal func recordLeadSequences() -> Void {
        layoutAnalyzer.leads.forEach { leadAndRecordTrickSequence($0) }
    }

    
    private func factorial(_ n: Int) -> Int {
        assert(n > 0)
        return n == 1 ? 1 : n * factorial(n - 1)
    }
    
    private func combinations(numberOfCards: Int, numberOfSlots: Int) -> Int {
        if numberOfCards == 0 || numberOfSlots == 0 || numberOfCards == numberOfSlots {
            return 1
        }
        assert(numberOfCards > numberOfSlots)
        return factorial(numberOfCards) / (factorial(numberOfSlots) * factorial(numberOfCards - numberOfSlots))
    }
    
    private func buildAllHandsAndAnalyze(moveIndex: Int, combinations: Int) {
        if moveIndex >= suitHolding[.east].cardRanges.endIndex {
            analyzeThisDeal(combinations: combinations)
            return
        }
        buildAllHandsAndAnalyze(moveIndex: moveIndex + 1, combinations: combinations)
        let eastRange = self.hand(.east).cardRanges[moveIndex]
        let westRange = self.hand(.west).cardRanges[moveIndex]
        // All the cards for a range start in the east and then are moved to the west...
        let numCards = eastRange.count  // This is the total number of cards in the range
        while eastRange.count > 0 {
            eastRange.count -= 1
            westRange.count += 1
            // You could compute this using eastRange or westRange for numberOfSlots...
            let newCombinations = combinations * self.combinations(numberOfCards: numCards, numberOfSlots: eastRange.count)
            buildAllHandsAndAnalyze(moveIndex: moveIndex + 1, combinations: newCombinations)
        }
        eastRange.count = numCards
        westRange.count = 0
    }

    private func analyzeThisDeal(combinations: Int) {
        assert(tricks.count == 0)
        let results = analyzeLeads(leads: self.layoutAnalyzer.leads)
        assert(layoutAnalyzer.leads.count == results.count)
        if recordCombinationStatistics {
            layoutAnalyzer.recordResults(results, layoutId: self.layoutId(), combinations: combinations)
        }
    }
    


    // BUGBUG:  Shouldnt these second/third/fourth hand things return Rank not Rank? ?
    // This function will only be called if there are two or more cards
    private func secondHand(trick: Trick, hand: CompositeCardRange) -> CountedCardRange {
        if trick.leadPlan.intent == .cashWinner { return hand.lowest(cover: nil) }
        
        let position = trick.nextToAct
        let ourChoices = suitHolding.choices(position)
        // Simplest case is that we have only one real choice of cards in this hand.  Just return a card now
        if ourChoices.all.count == 1 {
            return hand.lowest(cover: nil)
        }
        /*
         OPTOPMIZE THIS LATER.  FOR NOW JUST DO ALL CHOICES
        // Now if the rank in the a choice beats "mustBeat" then try all of them out
         */
        var lowestTrickRank: CountedCardRange? = nil
        var lowestTrickCount: Int = 13
        for choice in ourChoices.all {
            let rankRange = choice.lowest(cover: nil)
            let maxTricks = self.exploreSecondHandPlay(trick: trick, rank: rankRange)
            if lowestTrickRank == nil || lowestTrickCount > maxTricks {
                lowestTrickRank = rankRange
                lowestTrickCount = maxTricks
            }
        }
        return lowestTrickRank!
    }
    
    // Won't be called with an empty hand, so we can force unwrap
    private func thirdHand(trick: Trick, hand: CompositeCardRange) -> CountedCardRange {
        assert(trick.nextToAct.pairPosition == .ns)
        var cover: CountedCardRange? = nil
        if let min = trick.leadPlan.minThirdHand {
            if min > trick.winningRankRange {
                cover = min
            } else {
                if let maxThirdHand = trick.leadPlan.maxThirdHand,
                   maxThirdHand > trick.winningRankRange {
                    cover = trick.winningRankRange
                }
            }
        }
        return hand.lowest(cover: cover)
    }
    
    
    private func fourthHand(trick: Trick, hand: CompositeCardRange) -> CountedCardRange {
        let rankToCover = trick.winningPosition.pairPosition == .ns ? trick.winningRankRange : nil
        return hand.lowest(cover: rankToCover)
    }
    
    
    private func leadAgain() -> Int {
        if suitHolding[.north].count > 0 || suitHolding[.south].count > 0 {
            return maxTricksAllLeads()
        } else {
            return tricks.reduce(0) { return $1.winningPosition.pairPosition == .ns ? $0 + 1 : $0 }
        }
    }
    

 
    func playNextPosition(trick: Trick) -> Int {
        if trick.positionsPlayed == 4 {
            return self.leadAgain()
        }
        let position = trick.nextToAct
        let hand = self.hand(position)
        let numCards = hand.count
        var rank: CountedCardRange? = nil
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
            if position.pairPosition == .ew {
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
    
    // NOTE that this method is called by second hand logic.
    private func exploreSecondHandPlay(trick: Trick, rank: CountedCardRange) -> Int {
        return trick.play(rank, nextStep: self.playNextPosition)
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
    
    
    private func generateFinesses(position: Position, leadRank: CountedCardRange, partnerChoices: RangeChoices) -> [LeadPlan] {
        var leads: [LeadPlan] = []
        let winner = partnerChoices.win == nil ? nil : partnerChoices.win!.lowest(cover: nil)
        if let midChoices = partnerChoices.mid {
            for i in midChoices.indices {
                if leadRank.ranks.upperBound < midChoices[i].ranks.lowerBound {
                    let midRank = midChoices[i].lowest(cover: nil)
                    // OK a finess can happen with this rank.  It's higher than the one being lead
                    leads.append(LeadPlan(position: position, rankRange: leadRank, intent: .finesse, minThirdHand: midRank))
                    var j = i + 1
                    while j < midChoices.count {
                        let higherMidRank = midChoices[j].lowest(cover: nil)
                        leads.append(LeadPlan(position: position, rankRange: leadRank, intent: .finesse, minThirdHand: midRank, maxThirdHand: higherMidRank))
                        j += 1
                    }
                    if winner != nil {
                        leads.append(LeadPlan(position: position, rankRange: leadRank, intent: .finesse, minThirdHand: midRank, maxThirdHand: winner))
                    }
                }
            }
        }
        return leads
    }
    
    // Returns true if at least one lead was attempted.  Otherewise false if no leads from this hand
    // make any sense for promotion.  If both hands return false, caller must play a loser from short
    // hand
    private func generateLeads(choices: RangeChoices, partnerChoices: RangeChoices) -> [LeadPlan] {
        if choices.all.count == 0 {
            return []
        }
        let position = choices.position
        if partnerChoices.all.count == 0 {
            if let winners = choices.win {
                return [LeadPlan(position: position, rankRange: winners.lowest(cover: nil), intent: .cashWinner)]
            }
            return [LeadPlan(position: position, rankRange: self.hand(position).lowest(cover: nil), intent: .playLow)]
        }
        // TODO: Perhaps if next position shows out then we could avoid generating some of these leads.
        var leads: [LeadPlan] = []
        let partnerWinner = partnerChoices.win == nil ? nil : partnerChoices.win!.lowest(cover: nil)
        if let low = choices.low {
            let lowRank = low.lowest(cover: nil)
            if partnerChoices.low != nil {
                leads.append(LeadPlan(position: position, rankRange: lowRank, intent: .playLow))
            }
            leads.append(contentsOf: generateFinesses(position: position, leadRank: lowRank, partnerChoices: partnerChoices))
            if partnerWinner != nil {
                leads.append(LeadPlan(position: position, rankRange: lowRank, intent: .cashWinner, minThirdHand: partnerWinner))
            }
        }
        if let midChoices = choices.mid {
            for i in midChoices.indices {
                let midRank = midChoices[i].lowest(cover: nil)
                leads.append(contentsOf: generateFinesses(position: position, leadRank: midRank, partnerChoices:    partnerChoices))
                leads.append(LeadPlan(position: position, rankRange: midRank, intent: .ride))
                var j = i + 1
                while j < midChoices.count {
                    let higherMid = midChoices[j].lowest(cover: nil)
                    leads.append(LeadPlan(position: position, rankRange: midRank, intent: .ride, maxThirdHand: higherMid))
                    j += 1
                }
                if partnerWinner != nil {
                    leads.append(LeadPlan(position: position, rankRange: midRank, intent: .ride, maxThirdHand: partnerWinner))
                }
            }
        }
        if let win = choices.win {
            leads.append(LeadPlan(position: position, rankRange: win.lowest(cover: nil), intent: .cashWinner))
        }
        return leads
    }
    
    private func generateLeads() -> [LeadPlan] {
        let northChoices = suitHolding.choices(.north)
        let southChoices = suitHolding.choices(.south)
        var leads = generateLeads(choices: northChoices, partnerChoices: southChoices)
        leads.append(contentsOf: generateLeads(choices: southChoices, partnerChoices: northChoices))
        return leads
    }
    
    private func maxTricksAllLeads() -> Int {
        let results = analyzeLeads(leads: generateLeads())
        let maxTricks = results.reduce(0) { $1 > $0 ? $1 : $0 }
        return maxTricks
    }
    
    private func analyzeLeads(leads: [LeadPlan]) -> [Int] {
        return leads.map { lead($0) }
    }
    
    private func layoutId() -> SuitLayoutIdentifier? {
        if recordLayoutIds {
            var newLayout = self.suitHolding.initialLayout.clone()
            let eastHand = suitHolding[.east]
            let westHand = suitHolding[.west]
            assert(eastHand.cardRanges.endIndex == westHand.cardRanges.endIndex)
            for i in eastHand.cardRanges.indices {
                let ranks = eastHand.cardRanges[i].ranks
                var remainingEast = eastHand.cardRanges[i].count
                assert(remainingEast + westHand.cardRanges[i].count == ranks.count)
                for rank in ranks {
                    newLayout[rank] = remainingEast > 0 ? .east : .west
                    remainingEast -= 1
                }
            }
            return newLayout.id
        } else {
            return nil
        }
    }
    



    

}


