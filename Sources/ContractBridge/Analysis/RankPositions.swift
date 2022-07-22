//
//  File.swift
//  
//
//  Created by Ralph Lipe on 7/17/22.
//

import Foundation
import XCTest


public typealias RankPositionsId = UInt64

/// Contains an optional position for every rank.
///
/// Provides methods to analyze ranges of equivalent ranks by position
/// paris.  Specific rank ranges can be specified as "Played".
/// It also provies the ability to
/// shift rank holdings for a particular pair to consider all possible layout
/// combinations.
public struct RankPositions : Equatable {
    private var positions: UInt64
    private static let empty: UInt64 = 0x4444444444444
    
    /// Creates a new instance with all rank positions set to nil
    public init() {
        positions = Self.empty
    }
    
    /*
    /// Creates a new instance with positions for all ranks assigned initially by the RankPositionsId
    /// - Parameters:
    ///     - id:  A RankPositionsId describing the layout of ranks
    ///
    public init(id: RankPositionsId) {
        positions = id
    }
     */
    
    
    /// Copies the contents of a dictionary into a RankPositions structure.
    /// - Parameter dictionary: A dictionary containing positions of ranks
    public init(_ dictionary: [Rank: Position]) {
        self.init()
        dictionary.forEach {
            rank, position in
            self[rank] = position
        }
    }
    
    /// Accesses the position for the specified rank.
    /// - Parameter rank: The rank of the position element to access
    public subscript(rank: Rank) -> Position? {
        get {
            let masked = Int((positions >> (rank.rawValue * 4)) & 0b1111)
            return Position(rawValue: masked)
        }
        set {
            let rawValue: UInt64 = newValue == nil ? 4 : UInt64(newValue!.rawValue)
            let shift = rank.rawValue * 4
            positions = (positions & ~(0b1111 << shift)) | (rawValue << shift)
        }
    }
    
    
    /// A boolean that indicates if every rank has a non-nil posiition
    public var isFull: Bool {
        // NOTE: This relies on the fact that a value of 4 in any nibble shows a nil position
        return (positions & Self.empty) == 0
    }
    
    /// A boolenan that indicates if every rank has a nil position
    public var isEmpty: Bool {
        return positions == Self.empty
    }
    
    /*
    /// An identifier that can be used to efficently save rank positions.
    public var id: RankPositionsId {
        return positions
    }
    */

    
    /// Returns an orderd array  of closed ranges that contain ranks for the specified position.
    ///
    /// When considering possible plays for a position, many ranks are equivalant in value.  For example
    /// if a pair hold 478 in one position and 59 in the partner position, all of the ranks 4-9 are equivalent
    /// in value.  This method would return a range of 4...9 for either position.  If one position held all of
    /// the ranks then only the position with ranks would be considered playable, and the range would only
    /// be returned for that position.
    ///
    /// As ranks are played, ranges grow to encompass larger ranges.  Consider east holds the J, south holds
    /// the Q, and west holds the K.  In this example, each of the ranks would be in its own range J...J, Q...Q,
    /// and K...K for each position.  If south were to play the queen, then both east and west would have playable
    /// ranges of J...K since the ranks are now equivalent.
    /// - Parameter position: <#_position description#>
    /// - Returns: Array of `ClosedRange<Rank>` which contain one or more ranks for the
    public func playableRanges(for position: Position) -> [ClosedRange<Rank>] {
        var ranges: [ClosedRange<Rank>] = []
        var rangeLower: Rank? = nil
        var rangeUpper: Rank? = nil
        var positionHasRanks = false
        let positionPair = position.pair
        for rank in Rank.two...Rank.ace {
            let rankPair = self[rank]?.pair
            if rankPair == nil || rankPair == positionPair {
                if rangeLower == nil { rangeLower = rank }
                rangeUpper = rank
                positionHasRanks = positionHasRanks || (self[rank] == position)
            } else {
                if positionHasRanks {
                    ranges.append(rangeLower!...rangeUpper!)
                }
                positionHasRanks = false
                rangeLower = nil
                rangeUpper = nil
            }
        }
        if positionHasRanks {
            ranges.append(rangeLower!...rangeUpper!)
        }
        return ranges
    }
    
    /// Used to find the minimum rank for the specified `position` within the `range`
    /// - Parameters:
    ///   - range:Range to limit search to
    ///   - position: Position rank is assigned to
    /// - Returns: Minimum rank held by `position` within `range`
    public func min(in range: ClosedRange<Rank>, for _position: Position) -> Rank {
        for rank in range {
            if self[rank] == _position { return rank }
        }
        fatalError()
    }
    
    /// Plays the minimum rank within the specified `range` for the specified `position`
    /// - Parameters:
    ///   - range: Range to limit search to
    ///   - position: Position to play rank from
    /// - Returns: Minimum rank for `position`.  The rank will now contain a nil position`
    public mutating func play(_ range: ClosedRange<Rank>, from position: Position) -> Rank {
        let rank = min(in: range, for: position)
        self[rank] = nil
        return rank
    }
        
  
    
    // Standard math factorial
    private static func factorial(_ n: Int) -> Int {
        assert(n >= 0)
        return n <= 1 ? 1 : n * factorial(n - 1)
    }
    
    // Computes the combinations of n items placed into r positions.  Google "Combinations Formula" for more info.
    private static func combinations(n: Int, r: Int) -> Int {
        assert(n >= r)
        return (r == 0 || r == n) ? 1 : factorial(n) / (factorial(r) * factorial(n - r))
    }
    
    // TODO: Should callback include marked ranks?  Perhaps...
    internal mutating func shiftPairHoldings(pair: Pair, start: Rank?, marked: RankSet, combinations: Int, _ body: (RankPositions, _ combinations: Int) -> Void) -> Int {
        var rank: Rank? = start
        // Skip any opponent and undefined ranks until we hit one for this pair or we run off the end
        while rank != nil && self[rank!]?.pair != pair && !marked.contains(rank!) {
            rank = rank!.nextHigher
        }
        if rank == nil {
            body(self, combinations)
            return combinations
        } else {
            let pairPositions = pair.positions
            var ranks = RankSet()
            ranks.insert(rank!)
            // At this point we know we've got a range of ranks, which starts with, and includes rank
            self[rank!] = pairPositions.0
            rank = rank!.nextHigher
            while rank != nil {
                if let position = self[rank!] {
                    if position.pair == pair && !marked.contains(rank!) {
                        ranks.insert(rank!)
                        self[rank!] = pairPositions.0
                    } else {
                        break
                    }
                }
                rank = rank!.nextHigher
            }
            // At this point ranks contains all the ranks in this range.  The variable rank contains the next rank
            // to be considered (either an opponent has that rank or it is nil).  Either way, this is the value to
            // pass to the recursion to this function
            let n = ranks.count
            var combinationsConsidered = shiftPairHoldings(pair: pair, start: rank, marked: marked, combinations: combinations, body)
            while !ranks.isEmpty {
                self[ranks.removeFirst()] = pairPositions.1
                // You could compute this using either range for r...
                let newCombinations = combinations * Self.combinations(n: n, r: ranks.count)
                combinationsConsidered += shiftPairHoldings(pair: pair, start: rank, marked: marked, combinations: newCombinations, body)
            }
            return combinationsConsidered
        }
    }
    
    public func forAllCombinations(pair: Pair, marked: RankSet, _ body: (RankPositions, _ combinations: Int) -> Void) -> Int {
        var rp = self
        return rp.shiftPairHoldings(pair: pair, start: .two, marked: marked, combinations: 1, body)
    }
    
    public func mark(knownMarked: RankSet, leadFrom: Position, play: [Position: Rank]) -> RankSet {
        if knownMarked.isFull { return knownMarked }  // No reason to do any work if all the work has been done already
        var marked = knownMarked
        var winningPosition: Position? = nil
        var winningRank: Rank? = nil
        let opponents = leadFrom.pair.opponents
        for position in Position.allCases {
            if let rank = play[position] {
                if winningPosition == nil || rank > winningRank! {
                    winningPosition = position
                    winningRank = rank
                }
            } else {
                if position.pair == opponents {
                    marked.insertAll()
                    return marked
                }
            }
        }
        let forthPosition = leadFrom.previous
        let secondPosition = forthPosition.partner
        if winningPosition == forthPosition {
            var highestLeader = play[leadFrom]!
            if let thirdHandRank = play[leadFrom.partner] {
                if thirdHandRank > highestLeader { highestLeader = thirdHandRank }
            }
            // Since 4th position won, the winning rank MUST be higher than whatever was lead...
            var rank = winningRank!.nextLower!
            var foundLeadPairCard = false
            while rank > highestLeader && !foundLeadPairCard {
                if let position = self[rank] {
                    foundLeadPairCard = (position.pair == leadFrom.pair)
                }
                rank = rank.nextLower!
            }
            // Any cards between the highest plaeyd by the lead side and any other cards still heald by the lead
            // side, but lower than the winning card are marked to be in the 2nd hand.
            while rank > highestLeader {
                if let position = self[rank] {
                    if position == secondPosition { marked.insert(rank) }
                    assert(position != forthPosition)
                }
                rank = rank.nextLower!
            }
        } else {
            if secondPosition != winningPosition {  // The opponents won this one,,,
                for rank in winningRank!...Rank.ace {
                    if let rankPosition = self[rank] {
                        if rankPosition == secondPosition {
                            marked.insert(rank)
                        } else {
                            // This should be an opponent's card
                            assert(rankPosition != forthPosition)
                        }
                    }
                }
            }
        }
        return marked
    }
}




/* -- Some of this code may be useful somehwere else
var ranks: [Position: Rank] = [:]
var winningPosition: Position? = nil
var winningRank: Rank? = nil
for position in Position.allCases {
    if let range = play[position] {
        let rank = minRank(for: position, in: range)
        self[rank] = nil
        ranks[position] = rank
        if winningPosition == nil || rank > winningRank! {
            winningPosition = position
            winningRank = rank
        }
    } else {
        showedOutCount[position.rawValue] += 1
    }
}
if forthhHandInferences {
    let forthPosition = leadFrom.previous
    if winningPosition == forthPosition {
        // Here we can look backwards to see if 3rd hand indicates 2nd hand has a lower card
    } else {
        if fourthPosition.partner != winningPosition {  // The opponents won this one,,,
            // Here we can assume that 2nd hand has any cards greater than the winning card
            // Any card from winningRank...Ace that 2nd hand holds is now known
        }
    }
    // TODO: Implement somethine here...
}
return PlayResult(leadPosition: leadFrom, winningPosition: winningPosition!, play: ranks)
}


public mutating func undoPlay(_ playResult: PlayResult) {
for position in Position.allCases {
    if let rank = playResult.play[position] {
        self[rank] = position
    } else {
        showedOutCount[position.rawValue] -= 1
    }
    // TODO: Still need to deal with 4th hand known positions
}
}
 */

    
