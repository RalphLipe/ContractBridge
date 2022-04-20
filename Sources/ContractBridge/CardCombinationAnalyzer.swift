//
//  CardCombinationAnalyzer.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation


public class CardCombinationAnalyzer {
    let nsHands: PairCardRange
    let ewHands: PairCardRange
    var tricks: [Trick] = []
    var shortSide: Position? = nil
    var showsOut: Set<Position> = []

    var openingLeads: LeadAnalysis

    
    class Trick {
        let lead: LeadPlan
        var ranks: [Position:CountedCardRange] = [:]
        var winningPosition: Position
        public private(set) var positionsPlayed: Int
        public private(set) var nextToAct: Position
        var winningRankRange: CountedCardRange { ranks[self.winningPosition]! }
        var leadRankRange: CountedCardRange { ranks[self.lead.position]! }
        
        init(lead: LeadPlan) {
            self.lead = lead
            self.nextToAct = lead.position.next
            self.ranks[lead.position] = lead.rankRange
            self.winningPosition = lead.position
            self.positionsPlayed = 1
        }
        
        func play(_ rankRange: CountedCardRange?, nextStep: (Trick, Bool) -> Int, isFinal: Bool) -> Int {
            let currentPosition = self.nextToAct
            let currentWinningPosition = self.winningPosition
            self.positionsPlayed += 1
            self.ranks[currentPosition] = rankRange
            self.nextToAct = self.nextToAct.next
            if let rankRange = rankRange {
                rankRange.count -= 1
                if rankRange > self.winningRankRange { self.winningPosition = currentPosition }
            }
            let maxTricks = nextStep(self, isFinal)
            if rankRange != nil { rankRange!.count += 1 }
            self.ranks[currentPosition] = nil
            self.nextToAct = currentPosition
            self.winningPosition = currentWinningPosition
            self.positionsPlayed -= 1
            return maxTricks
        }
    }


    
    private func hand(_ position: Position) -> CompositeCardRange {
        return rangePair(position).hand(position)
    }
    
    private func rangePair(_ position: Position) -> PairCardRange {
        return position.pairPosition == .ns ? self.nsHands : self.ewHands
    }
    
    
    func choices(_ position: Position) -> RangeChoices {
        return self.rangePair(position).choices(position)
    }
    

    public init(partialDeal: Deal) {
        var allNS = partialDeal[.north]
        allNS.append(contentsOf: partialDeal[.south])
        
        let usedCards = Set<Card>(allNS)
        var allEW: [Card] = []
        for rank in Rank.allCases {
            let card = Card(rank, .spades)
            if usedCards.contains(card) == false {
                allEW.append(card)
            }
        }
        assert(allNS.count + allEW.count == 13)
        
        var longestHand: Int
        if partialDeal[.north].count < partialDeal[.south].count {
            shortSide = .north
            longestHand = partialDeal[.south].count
        } else if partialDeal[.north].count > partialDeal[.south].count {
            shortSide = .south
            longestHand = partialDeal[.north].count
        } else {
            longestHand = partialDeal[.north].count
        }
        
        let ranges = CountedCardRange.createRanges(from: partialDeal)[.spades]!
        
        self.nsHands = PairCardRange(allRanges: ranges, pair: .ns)
        self.ewHands = PairCardRange(allRanges: ranges, pair: .ew)
        let worstCaseTricks = CardCombinationAnalyzer.computeMinTricks(ns: allNS, ew: allEW, longestHand: longestHand)
        
        // Make the compiler happy by initializing these properties so "self" is valid before generating leads
        self.openingLeads = LeadAnalysis(leads: [], worstCase: worstCaseTricks)
    
        partialDeal[.north].forEach { self.hand(.north).solidRangeFor($0.rank).count += 1 }
        partialDeal[.south].forEach { self.hand(.south).solidRangeFor($0.rank).count += 1 }

        // Start with all the cards in east's hand
        allEW.forEach { self.hand(.east).solidRangeFor($0.rank).count += 1 }
        
        self.openingLeads = LeadAnalysis(leads: generateLeads(), worstCase: worstCaseTricks)
    }

    private func dealId() -> Int {
        let eastHand = self.hand(.east)
        var layout = 0
        for range in eastHand.cardRanges {
            layout = layout * 16 + range.count
        }
        return layout
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
    
    
    
    private func setPlayed(_ rank: CountedCardRange, playedFrom: Position, _ newValue: Bool) -> Void {
        // NOTE: We want to get the rangePair for the oppenents of "playedFrom" so just using .next
        // will give us one of the oppenents
        self.rangePair(playedFrom.next).opponentPlayed(rank, played: newValue)
    }
    

    // Note that this number may be greater than the number of winners you can actually claim.  To find
    // that number use numCashableWinners which returns the lesser of the length of the longest hand or
    // the result of this property.
    /* -- BUGBUG: not used - remove this....
    func numNorthSouthWinners(position: Position? = nil, winningRank: Rank? = nil) -> Int {
        let winningRank = winningRank == nil ? self.nsHands.winningRank : winningRank!
        var n = 0
        if let position = position {
            for rank in nsHands[position].ranks { if rank >= winningRank { n += 1} }
        } else {
            n = self.numNorthSouthWinners(position: .north, winningRank: winningRank) + self.numNorthSouthWinners(position: .south, winningRank: winningRank)
        }
        return n
    }
     */
    
    
    
    public func analyze() -> LeadAnalysis {
        // When this starts off all of the cards are in East, so start moving and analyzing
        buildAllHandsAndAnalyze(moveIndex: 0, combinations: 1)
        return openingLeads
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
        if moveIndex >= self.hand(.east).cardRanges.endIndex {
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

    

    // BUGBUG:  Shouldnt these second/third/fourth hand things return Rank not Rank? ?
    // This function will only be called if there are two or more cards
    private func secondHand(trick: Trick, hand: CompositeCardRange) -> CountedCardRange {
        if trick.lead.intent == .cashWinner { return hand.lowest(cover: nil) }
        
        let position = trick.nextToAct
        let ourChoices = self.choices(position)
        // Simplest case is that we have only one real choice of cards in this hand.  Just return a card now
        if ourChoices.all.count == 1 {
            return hand.lowest(cover: nil)
        }
        /*
        // Now we need to determine the effective minimum value for N/S rank played.  It is the maximum of
        // the current lead card, the minimum rank in the 3rd hand (regardless of what the trick shows) and
        // the minThirdHand in the lead.
        var mustBeat = trick.winningRank
        if let minTrickThirdHand = trick.lead.minThirdHand {
            mustBeat = max(mustBeat, minTrickThirdHand)
        }
        if let minRankThirdHand = self.hand(position.next).lowest(cover: nil) {
            mustBeat = max(mustBeat, minRankThirdHand)
        }
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
        /*
        var bestRank: Rank? = nil
        var bestTrickCount = 13
        for choice in ourChoices.allChoices {  // TODO: Needs to be
            let rank = choice.lowest(cover: nil)!
            let trickCount = self.explore(rank)
            if bestRank == nil || bestTrickCount > trickCount {
                bestRank = rank
                bestTrickCount = trickCount
            }
        }
        return bestRank!
         */
    }
    
    // Won't be called with an empty hand, so we can force unwrap
    private func thirdHand(trick: Trick, hand: CompositeCardRange) -> CountedCardRange {
        assert(trick.nextToAct.pairPosition == .ns)
        var cover: CountedCardRange? = nil
        if let min = trick.lead.minThirdHand {
            if min > trick.winningRankRange {
                cover = min
            } else {
                if let maxThirdHand = trick.lead.maxThirdHand,
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
    
    // NOTE: Position is ignored
    private func leadAgain(isFinal: Bool) -> Int {
        if self.hand(.north).count > 0 || self.hand(.south).count > 0 {
            return maxTricksAllLeads(isFinal: isFinal)
        } else {
            return analyzeTrickSequence(isFinal: isFinal)
        }
    }
    
    private func analyzeTrickSequence(isFinal: Bool) -> Int {
        let nsTricks = self.tricks.reduce(0) { return $1.winningPosition.pairPosition == .ns ? $0 + 1 : $0 }
        if isFinal {
         //   hackReportSequence(nsTricks: nsTricks)
        }
        return nsTricks
    }
    

   /*
    private func hackReportSequence(nsTricks: Int) {
        if nsTricks > self.worstCaseTricks { // Show all attempst
            // TODO: self.combinationsThisDeal was used here.  It's gone new....
            print("Sequence wins \(nsTricks) tricks, times")
            self.tricks.forEach {
                trick in
                if trick.winningPosition.pairPosition == .ns {
                    print("  W - ", terminator: "")
                } else {
                    print("  l - ", terminator: "")
                }
                switch trick.lead.intent {
                case .finesse:
                    print("finesse from \(trick.lead.position) to \(trick.lead.minThirdHand!)")
                default:
                    print("\(trick.lead.intent) \(trick.leadRankRange) from \(trick.lead.position)")
                }
                print("    ", terminator: "")
                var position = trick.lead.position
                repeat {
                    if let rank = trick.ranks[position] {
                        print("\(position): \(rank)   ", terminator: "")
                    } else {
                        print("\(position): ---   ", terminator: "")
                    }
                    position = position.next
                } while position != trick.lead.position
                print("")
            }
        }
    }
    
*/
    
    func playNextPosition(trick: Trick, isFinal: Bool) -> Int {
        if trick.positionsPlayed == 4 {
            return self.leadAgain(isFinal: isFinal)
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
            self.setPlayed(rank, playedFrom: position, true)
            maxTricks = trick.play(rank, nextStep: self.playNextPosition, isFinal: isFinal)
            self.setPlayed(rank, playedFrom: position, false)
        } else {
            if position.pairPosition == .ew {
                let hadShownOut = self.showsOut.contains(position)
                self.showsOut.insert(position)
                maxTricks = trick.play(nil, nextStep: self.playNextPosition, isFinal: isFinal)
                if !hadShownOut { self.showsOut.remove(position) }
            } else {
                maxTricks = trick.play(nil, nextStep: self.playNextPosition, isFinal: isFinal)
            }
        }
        return maxTricks
    }
    
    // NOTE that this method is called by second hand logic.
    private func exploreSecondHandPlay(trick: Trick, rank: CountedCardRange) -> Int {
        let position = trick.nextToAct
        self.setPlayed(rank, playedFrom: position, true)
        let maxTricks = trick.play(rank, nextStep: self.playNextPosition, isFinal: false)
        self.setPlayed(rank, playedFrom: position, false)
        return maxTricks
    }
    
    
    private func lead(_ lead: LeadPlan, isFinal: Bool) -> Int {
        lead.rankRange.count -= 1
        let trick = Trick(lead: lead)
        self.tricks.append(trick)
        let maxTricks = self.playNextPosition(trick: trick, isFinal: isFinal)
        lead.rankRange.count += 1
        _ = self.tricks.removeLast()
        return maxTricks
    }
    
    /*
    func finesse(_ leadRank: Rank, position: Position, winningRank: Rank) -> Bool {
        var leadFinesse = false
        let partner = position.partner
        for i in nsHands[partner].childRanges.indices {
            if let finesseRank = nsHands[partner].childRanges[i].lowest(cover: nil) {
                if finesseRank < winningRank && finesseRank > .seven {    // Again BUGBUG .Seven is goofy
                    self.lead(leadRank, position: position, intent: .finesse(rank: finesseRank))
                    leadFinesse = true
                }
            }
        }
        return leadFinesse
    }
    
    // At this point we know the following:
    //      Both hands contain at least one card
    //      All of the cards are not winners
    //      All of the cards in the short hand (if there is one) are not winners
    // Now we need to determine if there are any reasonable leads from this hand.  You can always cash a winner
    // so if there are winners we can try that one.  You can finesse if this hand has low cards and partner has
    // mid-range cards.  We can play low toward partner's winner (not really different from cashing a winner in
    // the other hand).
    // Things to consider:
    //      What if we have only mid cards?  Just lead them?  If they are in different ranges then finesse from
    //      partner?  Maybe eleminate possible finesses and letting ride from either side and then just play low?
    
    private func leadTowardPartner(choices: RangeChoices, partnerChoices: RangeChoices) -> Bool {
        assert(false)   // This is all broken!  Write some code!!!
        var didSomething = false
        if let winners = choices.win {
            let rank = winners.lowest(cover: nil)!
            self.lead(rank, position: choices.position, intent: .cashWinner(rank: rank))
            didSomething = true
        }
        if let lowRanks = choices.low {
            let lowLeadRank = lowRanks.lowest(cover: nil)!
            if let partnerMid = partnerChoices.mid {
                for range in partnerMid {
                    let finesseRank = range.lowest(cover: nil)!
                    self.lead(lowLeadRank, position: choices.position, intent: .finesse(rank: finesseRank))
                    didSomething = true
                }
            }
        }
        if let midChoices = choices.mid {
            // BUGBUG -- What if partner has cards that can cover our "ride" card but can't win.
            // I think this situation would be a good opportunity to ride a card.
            if partnerChoices.win != nil {
                for choice in midChoices {
                    let rank = choice.lowest(cover: nil)!
                    self.lead(rank, position: choices.position, intent: .ride)
                }
            }
        }
        return didSomething
    }
    */
   // private func playOutHand(choices: RangeChoices) -> Lead {
        // This is the only hand with any cards in it.  Now play all winners followed by playing a card low
        // to see if we can produce any more winners.
    //    let position = choices.position

    //}/
    
    
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
        let northChoices = self.choices(.north)
        let southChoices = self.choices(.south)
        var leads = generateLeads(choices: northChoices, partnerChoices: southChoices)
        leads.append(contentsOf: generateLeads(choices: southChoices, partnerChoices: northChoices))
        return leads
    }
    
    private func maxTricksAllLeads(isFinal: Bool) -> Int {
        let results = analyzeLeads(leads: generateLeads(), isFinal: isFinal)
        let maxTricks = results.reduce(0) { $1 > $0 ? $1 : $0 }
        return maxTricks
    }
    
    private func analyzeLeads(leads: [LeadPlan], isFinal: Bool) -> [Int] {

        assert(leads.count > 0)
        var leadResults: [Int] = []
        for lead in leads {
            leadResults.append(self.lead(lead, isFinal: false))
        }
        return leadResults
    }
    
    private func analyzeThisDeal(combinations: Int) {
        assert(self.tricks.count == 0)
       // self.combinationsThisDeal = combinations    // This is only used to record final sequences...
        let results = analyzeLeads(leads: self.openingLeads.leads, isFinal: true)
        
      //  let maxTricks = results.reduce(0) { $1 > $0 ? $1 : $0 }
     //   for result in results {
     //       if result == maxTricks {
      //          let sanityCheck = lead(result.lead, isFinal: true)
       //         assert(sanityCheck == maxTricks)
       //     }
       // }
        assert(self.openingLeads.leads.count == results.count)
        self.openingLeads.recordResults(results, dealId: self.dealId(), combinations: combinations)

    }

    /*
    private func numRanksCovering(_ covering: Rank, position: Position? = nil) -> Int {
        assert(position == nil || position!.pairPosition == .ns)
        if let position = position {
            return hand(position).ranks.reduce(0) { $1 >= covering ? 1 : 0 }
        } else {
            return numRanksCovering(covering, position: .north) + numRanksCovering(covering, position: .south)
        }
    }
    
    // This method works for
    private func canCover(_ cover: Rank, position: Position) -> Bool {
        if let coverRank = self.hand(position).lowest(cover: cover) { return coverRank >= cover }
        return false
    
    }
     */
    /* -- Still want to do this but commented out for now
    // Returns true if one winner was cashed.
    private func cashOneWinner(position: Position, winningRank: Rank) -> Bool {
        if let rank = nsHands[position].lowest(cover: winningRank) {
            if rank >= winningRank {
                self.lead(rank, position: position, intent: .cashWinner, minThirdHand: rank)
                return true
            }
        }
        return false
    }
    
    private func cashWinners() -> Bool {
        let winningRank = self.nsHands.winningRank
        let shortPosition = self.shortSide ?? .north
        // If the total number of winners is greater than or equal to the longest side then all
        // the winners should just be cashed.  Short side first.
        if numRanksCovering(winningRank) >= self.nsHands[shortPosition.partner].numberOfCards {
            if !cashOneWinner(position: shortPosition, winningRank: winningRank) {
                _ = cashOneWinner(position: shortPosition.partner, winningRank: winningRank)
            }
            return true
        }
        // If the short hand has all winning cards then we cash one of them and are done...
        if numRanksCovering(winningRank, position: shortPosition) == nsHands[shortPosition].numberOfCards {
            return cashOneWinner(position: shortPosition, winningRank: winningRank)
        }
        return false
    }
    
     */
    
    

}


