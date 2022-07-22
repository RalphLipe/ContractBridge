//
//  RankSet.swift
//  
//
//  Created by Ralph Lipe on 6/5/22.
//

import Foundation


public enum RankSetError: Error {
    case invalidCharacter(_ character: Character)
    case duplicate(_ rank: Rank)
}

public struct RankSetIterator: IteratorProtocol {
    private var ranks: UInt16
    private var nextRank: Rank?

    init(_ ranks: UInt16) {
        self.ranks = ranks
        self.nextRank = .two
    }
    
    public mutating func next() -> Rank? {
        while ranks != 0 && (ranks & 1) == 0 {
            nextRank = nextRank!.nextHigher
            ranks >>= 1
        }
        if ranks == 0 { return nil }
        assert(ranks & 1 == 1)
        let rank = nextRank!
        nextRank = rank.nextHigher
        ranks >>= 1
        return rank
    }
}

/// Structure that efficently represents a set of ranks.  This strucure contains a subest of Set<Rank> and adds a few methods.
/// The idea is to be efficient at basic operations and require small amounts of storage.
/// This set implementation is *sorted*
public struct RankSet: Sequence, ExpressibleByArrayLiteral {
    var ranks: UInt16
    
    public init() {
        ranks = 0
    }

    public init<S>(_ sequence: S) where S: Sequence, S.Element == Rank {
        self.init()
        sequence.forEach { insert($0) }
    }
    
    public init(arrayLiteral elements: Rank...) {
        self.init()
        elements.forEach { insert($0) }
    }
    
    internal init(_ ranks: UInt16) {
        self.ranks = ranks
    }

    public init(from: String) throws {
        self.init()
        for c in from {
            if let rank = Rank(from: String(c)) {
                if !self.insert(rank) {
                    throw RankSetError.duplicate(rank)
                }
            } else {
                throw RankSetError.invalidCharacter(c)
            }
        }
    }
    
    internal func bitMask(_ rank: Rank) -> UInt16 {
        return 1 << rank.rawValue
    }
    
    public func contains(_ rank: Rank) -> Bool {
        return (bitMask(rank) & ranks) != 0
    }
    
    @discardableResult public mutating func insert(_ rank: Rank) -> Bool {
        let bitMask = bitMask(rank)
        let inserted = (ranks & bitMask) == 0
        ranks = ranks | bitMask
        return inserted
    }
    
    @discardableResult public mutating func remove(_ rank: Rank) -> Rank? {
        let bitMask = bitMask(rank)
        let removed = (ranks & bitMask) != 0
        ranks = ranks & (~bitMask)
        return removed ? rank : nil
    }
    
    public mutating func removeAll() {
        ranks = 0
    }
    
    public mutating func insertAll() {
        ranks = 0x1FFF
    }
    
    public mutating func removeFirst() -> Rank {
        guard let rank = min() else { fatalError() }
        remove(rank)
        return rank
    }
    
    public func min() -> Rank? {
        if ranks == 0 { return nil }
        return Rank(rawValue: ranks.trailingZeroBitCount)
    }
    
    public func union(_ other: RankSet) -> RankSet {
        return RankSet(ranks | other.ranks)
    }
    
    public mutating func formUnion(_ other: RankSet) {
        ranks = ranks | other.ranks
    }
    
    public func intersection(_ other: RankSet) -> RankSet {
        return RankSet(ranks & other.ranks)
    }
    
    public mutating func formIntersection(_ other: RankSet) {
        ranks = ranks & other.ranks
    }
    
    public func makeIterator() -> RankSetIterator {
        return RankSetIterator(ranks)
    }
    
    public var count: Int {
        return ranks.nonzeroBitCount
    }
    
    public var isEmpty: Bool {
        return ranks == 0
    }
    
    public var isFull: Bool {
        return ranks == 0x1FFF  // This is 13 bits set - all ranks present
    }
    
    // Because the iterator presents the sequence
    // in sorted order this is more efficent than the
    // default implementation.
    public func sorted() -> [Rank] {
        var sortedRanks = [Rank]()
        sortedRanks.reserveCapacity(count)
        sortedRanks.append(contentsOf: self)
        return sortedRanks
    }
    
    
    public func serialized() -> String {
        return sorted().reversed().map { "\($0, style: .character)" }.joined()
    }
}



public extension String.StringInterpolation {
    mutating func appendInterpolation(_ ranks: RankSet, style: ContractBridge.Style = .symbol) {
        switch style {
        case .symbol:
            appendLiteral(ranks.serialized())
        case .character, .name:
            appendLiteral(ranks.sorted().reversed().map { "\($0, style: style)" }.joined(separator: ", "))
        }
    }
}


public extension Set where Element == Rank {
    init(_ rankSet: RankSet) {
        self.init(minimumCapacity: rankSet.count)
        self.formUnion(rankSet)
    }
}
