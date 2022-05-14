//
//  SuitLayout.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public typealias SuitLayoutIdentifier = Int

public struct SuitLayout {
    private var rankPositions: [Position?]
    
    public var isFullLayout: Bool {
        for position in rankPositions {
            if position == nil { return false }
        }
        return true
    }
    
    public struct PairRange {
        let pair: PairPosition?
        let ranks: ClosedRange<Rank>
    }
    
    public var id: SuitLayoutIdentifier {
        return (rankPositions.reversed().reduce(0) { return ($0 * 5) + ($1 == nil ? 0 : 1 + $1!.rawValue) })
    }
    
    public init() {
        self.rankPositions = Array<Position?>(repeating: nil, count: Rank.allCases.count)
    }

    public init(_ from: SuitLayout) {
        self.rankPositions = from.rankPositions
    }

    public init(suitHolding: SuitHolding) {
        self.init()
        for position in Position.allCases {
            for rank in suitHolding[position].ranks {
                self[rank] = position
            }
        }
    }

    public init(suitLayoutId: SuitLayoutIdentifier) {
        self.init()
        var id = suitLayoutId
        for rank in Rank.allCases {
            let val = id % 5
            self[rank] = val == 0 ? nil : Position(rawValue: val - 1)
            id /= 5
        }
    }
    
    public init(deal: Deal, suit: Suit) {
        self.init()
        for position in Position.allCases {
            setRanks(deal[position].ranksFor(suit), position: position)
        }
    }
    
    public mutating func assignNilPositions(_ position: Position) {
        for rank in Rank.allCases {
            if self[rank] == nil { self[rank] = position }
        }
    }
    
    public mutating func setRanks(_ ranks: Set<Rank>, position: Position?) {
        ranks.forEach { self[$0] = position }
    }
    
    /*  TODO: Is this used anywhere?  Seems kinda random. Put it back if useful
    public func toDeal(suit: Suit) -> Deal {
        var deal = Deal()
        for position in Position.allCases {
            deal[position] = Set(ranksFor(position: position).map { Card($0, suit) })
        }
        return deal
    }
     */
    
    public subscript(rank: Rank) -> Position? {
        get { return rankPositions[rank.rawValue] }
        set { rankPositions[rank.rawValue] = newValue }
    }
    
    public func ranksFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Set<Rank> {
        var ranks = Set<Rank>()
        _range.forEach { if self[$0] == position { ranks.insert($0) } }
        return ranks
    }
    
    public func countFor(position: Position, in _range: ClosedRange<Rank> = Rank.two...Rank.ace) -> Int {
        return _range.reduce(0) { self[$1] == position ? $0 + 1 : $0}
    }
    
    public mutating func reassignRanks(pairs: Set<PairPosition> = [.ns, .ew], random: Bool) {
        for range in pairRanges() {
            if let rangePair = range.pair,
                pairs.contains(rangePair) {
                let positions = rangePair.positions
                var count0 = ranksFor(position: positions.0, in: range.ranks).count
                var count1 = ranksFor(position: positions.1, in: range.ranks).count
                var ranks = range.ranks.map { $0 }
                assert(ranks.count == count0 + count1)
                if random { ranks.shuffle() }
                while count0 > 0 {
                    self[ranks.removeFirst()] = positions.0
                    count0 -= 1
                }
                while count1 > 0 {
                    self[ranks.removeFirst()] = positions.1
                    count1 -= 1
                }
                
            }
        }
    }
    
    public func pairRanges() -> [PairRange] {
        var ranges = Array<PairRange>()
        var rangeLower = Rank.two
        var rangeUpper = Rank.two
        var lastPair: PairPosition? = self[.two]?.pairPosition
        for rank in Rank.three...Rank.ace {
            let thisPair = self[rank]?.pairPosition
            if thisPair == lastPair {
                rangeUpper = rank
            } else {
                ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
                rangeLower = rank
                rangeUpper = rank
                lastPair = thisPair
            }
        }
        ranges.append(PairRange(pair: lastPair, ranks: rangeLower...rangeUpper))
        return ranges
    }
   
    // TODO:  *************** EVERYTHING FROM HERE ON DOWN SEEMS LIKE IT SHOULD GO SOMEWHERE ELSE!
    
    // TODO: What is the roll of this function?  It it to provide a base for a particular
    // layout?  For worst case in all opponent configuration for opponents?    Does neither
    // as far as I can tell...
    public func minimumTricksFor(_ pair: PairPosition) -> Int {
        let winPositions = pair.positions
        let ranks0 = ranksFor(position: winPositions.0)
        let ranks1 = ranksFor(position: winPositions.1)
        let opponentPositions = pair.opponents.positions
        let oppsRanks0 = ranksFor(position: opponentPositions.0)
        let oppsRanks1 = ranksFor(position: opponentPositions.1)
        
        var pairSorted = Array(ranks0.union(ranks1))
        pairSorted.sort()
        pairSorted.reverse()
        var opponentSorted = Array(oppsRanks0.union(oppsRanks1))
        opponentSorted.sort()
        opponentSorted.reverse()

        // N/S can only win as any tricks as the length of the longest hand  Strip off low cards
        let maxPossible = max(ranks0.count, ranks1.count)
        while pairSorted.count > maxPossible {
            _ = pairSorted.removeLast()
        }
        
        let oppsMaxPossible = max(oppsRanks0.count, oppsRanks1.count)
        while opponentSorted.count > oppsMaxPossible {
            _ = opponentSorted.removeLast()
        }
        
        var minTricks = 0
        while opponentSorted.count > 0 && pairSorted.count > 0 {
            let pairPlayed = pairSorted.removeFirst()
            if pairPlayed > opponentSorted.first! {
                minTricks += 1
                _ = opponentSorted.removeLast()
            } else {
                _ = opponentSorted.removeFirst()
            }
        }
        return minTricks + pairSorted.count
    }
     

    
    private func allWinners(_ position: Position) -> Bool {
        var count = countFor(position: position)
        var rank = Rank.ace
        while count > 0 {
            if self[rank] != position { return false }
            rank = rank.nextLower!
            count -= 1
        }
        return true
    }
    
    
    private mutating func distributeHighCards(rank: Rank?, results: inout Set<SuitLayoutIdentifier>) {
        if let rank = rank {
            for position in [Position.north, Position.south, Position.east] {
                self[rank] = position
                distributeHighCards(rank: rank.nextHigher, results: &results)
            }
        } else {
            // A layout is only interesting if:
            // North has >= cards in south
            // North/South can not trivially win all tricks
            // East/West can not trivially win all tricks
            let nCount = countFor(position: .north)
            let sCount = countFor(position: .south)
            if nCount >= sCount && sCount > 0 && minimumTricksFor(.ns) < nCount && minimumTricksFor(.ew) < countFor(position: .east) {
                var layout = SuitLayout(self)
                layout.reassignRanks(random: false)
                if layout.allWinners(.south) == false {
                    results.insert(layout.id)
                }
            }
        }
    }
    
    private mutating func distributeLowCards(position: Position, startRank: Rank, results: inout Set<SuitLayoutIdentifier>, endRank: Rank = Rank.eight) {
        if startRank == endRank {
            distributeHighCards(rank: startRank, results: &results)
        } else {
            for rank in startRank..<endRank {
                self[rank] = position
            }
            if position == .east {
                distributeHighCards(rank: endRank, results: &results)
            } else {
                var nextPosStart: Rank? = endRank
                let nextPosition = position == .north ? Position.south : .east
                while nextPosStart != nil && nextPosStart! >= startRank {
                    distributeLowCards(position: nextPosition, startRank: nextPosStart!, results: &results)
                    nextPosStart = nextPosStart?.nextLower
                }
            }
        }
       
    }
    
    
    public static func generateLayouts() -> Set<SuitLayoutIdentifier> {
        var startingLayout = SuitLayout()
        Rank.allCases.forEach { startingLayout[$0] = .north }
        var results: Set<SuitLayoutIdentifier> = []
        startingLayout.distributeLowCards(position: .north, startRank: Rank.two, results: &results)
        for id in results {
            var layout = SuitLayout(suitLayoutId: id)
            if layout.countFor(position: .north) == layout.countFor(position: .south) {
                for rank in Rank.allCases {
                    if layout[rank] == .north {
                        layout[rank] = .south
                    } else if layout[rank] == .south {
                        layout[rank] = .north
                    }
                }
                if results.contains(layout.id) {
                    print("removing \(id), same as \(layout.id)")
                    results.remove(id)
                }
            }
        }
        return results
    }
}

// TODO:  This is ugly.  Make is nicer...
extension SuitLayout: CustomStringConvertible {
    public var description: String {
        var result = ""
        for position in Position.allCases {
            result += "\(position.shortDescription): \(ranksFor(position: position).description)"
            if position != Position.west { result += " "}
        }
        return result
    }
}
