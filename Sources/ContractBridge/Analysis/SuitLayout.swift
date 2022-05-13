//
//  SuitLayout.swift
//  
//
//  Created by Ralph Lipe on 4/23/22.
//

import Foundation


public typealias SuitLayoutIdentifier = Int

public struct SuitLayout {
    internal var rankPositions: [Position?]
    
    public var isFullLayout: Bool {
        for position in rankPositions {
            if position == nil { return false }
        }
        return true
    }
    
    public struct PairRange {
        let pair: PairPosition
        let ranks: ClosedRange<Rank>
    }
    
    public var id: SuitLayoutIdentifier {
        return (rankPositions.reversed().reduce(0) { return ($0 * 5) + ($1 == nil ? 0 : 1 + $1!.rawValue) })
    }
    

    private init(rankPositions: [Position]) {
        if rankPositions.count != Rank.allCases.count { fatalError() }
        self.rankPositions = rankPositions
    }
    
    public init(from: SuitLayout) {
        self.rankPositions = from.rankPositions
    }

    public init(from: SuitHolding) {
        self.rankPositions = Array(repeating: nil, count: Rank.allCases.count)
        for position in Position.allCases {
            for rank in from[position].ranks {
                self[rank] = position
            }
        }
    }

    public init(suitLayoutId: SuitLayoutIdentifier) {
        var id = suitLayoutId
        rankPositions = []
        for _ in Rank.allCases {
            let val = id % 5
            var position: Position? = nil
            if val > 0 { position = Position(rawValue: val - 1) }
            rankPositions.append(position)
            id /= 5
        }
    }
    
    internal mutating func setRanks(_ ranks: Set<Rank>, position: Position?) {
        ranks.forEach { self[$0] = position }
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>, east: Set<Rank>, west: Set<Rank>) {
        assert(north.union(south).union(east).union(west).count == Rank.allCases.count)
        self.rankPositions = Array(repeating: nil, count: Rank.allCases.count)
        setRanks(north, position: .north)
        setRanks(south, position: .south)
        setRanks(east, position: .east)
        setRanks(west, position: .west)
    }
    
    public init(suit: Suit, north: Set<Rank>, south: Set<Rank>) {
        let allRemaining = Set(Rank.allCases).subtracting(north.union(south))
        self.init(suit: suit, north: north, south: south, east: allRemaining, west: [])
    }
    
    public func toDeal(suit: Suit) -> Deal {
        var deal = Deal()
        for position in Position.allCases {
            deal[position] = Set(ranksFor(position: position).map { Card($0, suit) })
        }
        return deal
    }
    
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
            if pairs.contains(range.pair) {
                let positions = range.pair.positions
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
        if isFullLayout == false { fatalError() }   // TODO: Think about this.  Make optional ranges?
        var lastPair = self[.two]!.pairPosition
        for rank in Rank.three...Rank.ace {
            let thisPair = self[rank]!.pairPosition
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
   
    
    /*
    struct FUTURESTUFF {
        var ranks0: [Rank]
        var ranks1: [Rank]
        let pair: PairPosition
        init(_ suitLayout: SuitLayout, pair: PairPosition) {
            self.pair = pair
            let positions = pair.positions
            self.ranks0 = Array(suitLayout.ranksFor(position: positions.0))
            self.ranks1 = Array(suitLayout.ranksFor(position: positions.1))
            self.ranks0.sort()
            self.ranks0.reverse()
            self.ranks1.sort()
            self.ranks1.reverse()
        }
        var canPlay: Bool { return ranks0.count + ranks1.count > 0 }
       // var
    }
    */
    
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
                var layout = SuitLayout(from: self)
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
        var startingLayout = SuitLayout(rankPositions: Array<Position>(repeating: .north, count: Rank.allCases.count))
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
