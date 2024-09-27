//
//  RankPositions.swift
//  
//
//  Created by Ralph Lipe on 7/20/22.
//

import XCTest
import ContractBridge

class RankPositionsTest: XCTestCase {



    func testBasics() throws {
        var rp = RankPositions()
        XCTAssertTrue(rp.isEmpty)
        XCTAssertFalse(rp.isFull)
        rp[.two] = .north
        XCTAssertFalse(rp.isEmpty)
        XCTAssertFalse(rp.isFull)
        rp[.five] = .north
        
        var rpCopy = rp

        XCTAssertEqual(rpCopy, rp)
        
        rpCopy[.eight] = .south
        XCTAssertNotEqual(rpCopy, rp)
        
        let dict: Dictionary<Rank, Direction> = [.two: .north, .five: .north, .eight: .south]
        let rpFromDict = RankPositions(dict)
        XCTAssertEqual(rpCopy, rpFromDict)
       
        var rpFull = RankPositions()
        Rank.allCases.forEach { rpFull[$0] = .east }
        XCTAssertTrue(rpFull.isFull)
        XCTAssertFalse(rpFull.isEmpty)
        
        rpFull[.seven] = nil
        XCTAssertFalse(rpFull.isFull)
        XCTAssertFalse(rpFull.isEmpty)
    }

    public func testPositionSubscript() throws {
        var rp = RankPositions()
        XCTAssertTrue(rp[nil].isFull)
        
        rp[.south] = [.five, .eight, .ten]
        XCTAssertEqual(rp.count(for: .south), 3)
        XCTAssertEqual(rp[.eight], .south)
        
        rp[.nine] = .south
        let southRanks = Array<Rank>(rp[.south])
        XCTAssertEqual(southRanks, [.five, .eight, .nine, .ten])
        
        rp.reassignRanks(from: nil, to: .east)
        let eastRanks = Array<Rank>(rp[.east])
        XCTAssertEqual(eastRanks, [.two, .three, .four, .six, .seven, .jack, .queen, .king, .ace])
        
        rp[.north] = [.jack, .queen, .ace]
        XCTAssertTrue(rp.isFull)
        XCTAssertEqual(rp[.north].count, rp.count(for: .north))
        
    }
    
    public func testNormalized() throws {
        var rp = RankPositions()
        rp[.north] = [.ace, .queen, .six]
        rp[.south] = [.king, .eight, .seven, .two]
        rp[.east] = [.jack, .nine, .three]
        rp[.west] = [.ten, .five, .four]
        XCTAssertTrue(rp.isFull)
        let rpNorm = rp.normalized()
        let northRanks = Array<Rank>(rpNorm[.north])
        let southRanks = Array<Rank>(rpNorm[.south])
        let eastRanks = Array<Rank>(rpNorm[.east])
        let westRanks = Array<Rank>(rpNorm[.west])
        XCTAssertEqual(northRanks, [.eight, .king, .ace])
        XCTAssertEqual(southRanks, [.two, .six, .seven, .queen])
        XCTAssertEqual(eastRanks, [.five, .ten, .jack])
        XCTAssertEqual(westRanks, [.three, .four, .nine])
    }
    
    public func testRandomized() throws {
        var rp = RankPositions()
        rp[.north] = [.ace, .queen, .eight]
        rp[.south] = [.king, .seven, .six, .two]
        rp[.east] = [.jack, .nine, .three]
        rp[.west] = [.ten, .five, .four]
        XCTAssertTrue(rp.isFull)
        var numNonEqual = 0
        let numIterations = 100
        for _ in 1...numIterations {
            let rpShuffled = rp.equalRanksShuffled()
            // We will assume that the ranks will sometimes be equal to the original assignment, so it's not
            // an error if they are equal, but if less than half are diffrent, we have a problem
            for position in Direction.allCases {
                XCTAssertEqual(rp.count(for: position), rpShuffled.count(for: position))
                XCTAssertEqual(rp.playableRanges(for: position), rpShuffled.playableRanges(for: position))
                if (rp[position] != rpShuffled[position]) { numNonEqual += 1 }
            }
        }
        // NOTE:  In a degenerate case this could fail, even though it worked.
        // There have been numItterations and each position is checked on each time through the loop so there
        // could be as many as 4*numIterrations non-equal ranks.  We will be happy with 1/2 of that
        XCTAssert(numNonEqual > numIterations * 4 / 2)
    }
    
    public struct PosRanges {
        var north = [ClosedRange<Rank>]()
        var south = [ClosedRange<Rank>]()
        var east = [ClosedRange<Rank>]()
        var west = [ClosedRange<Rank>]()
        public mutating func update(_ rankPositions: RankPositions) {
            north = rankPositions.playableRanges(for: .north)
            south = rankPositions.playableRanges(for: .south)
            east = rankPositions.playableRanges(for: .east)
            west = rankPositions.playableRanges(for: .west)
        }
        
    }
    
    func testPlayableRanges() throws {
        var posRanges = PosRanges()
        var rp = RankPositions()
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north.count, 0)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 0)
        XCTAssertEqual(posRanges.west.count, 0)

        // N:- E:7 S:- W:-
        rp[.seven] = .east
        posRanges.update(rp)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.ace)
        XCTAssertEqual(posRanges.north.count, 0)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 0)
        
        // N:A E:7 S:- W:-
        rp[.ace] = .north
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.ace)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.king)
        XCTAssertEqual(posRanges.north.count, 1)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 0)
        
        
        // N:AQ E:7 S:- W:-
        rp[.queen] = .north
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.ace)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.jack)
        XCTAssertEqual(posRanges.north.count, 1)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 0)
        
        // N:AQ E:7 S:- W:K
        rp[.king] = .west
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.north[1], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.jack)
        XCTAssertEqual(posRanges.west[0], Rank.king...Rank.king)
        XCTAssertEqual(posRanges.north.count, 2)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 1)
        
        
        // N:AQ E:7 S:- W:K4
        rp[.four] = .west
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.north[1], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.jack)
        XCTAssertEqual(posRanges.west[0], Rank.two...Rank.jack)
        XCTAssertEqual(posRanges.west[1], Rank.king...Rank.king)
        XCTAssertEqual(posRanges.north.count, 2)
        XCTAssertEqual(posRanges.south.count, 0)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 2)
        
        // N:AQ E:7 S:T W:K4
        rp[.ten] = .south
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.north[1], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.south[0], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.east[0], Rank.two...Rank.nine)
        XCTAssertEqual(posRanges.west[0], Rank.two...Rank.nine)
        XCTAssertEqual(posRanges.west[1], Rank.king...Rank.king)
        XCTAssertEqual(posRanges.north.count, 2)
        XCTAssertEqual(posRanges.south.count, 1)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 2)

        // N:AQ E:7 S:T2 W:K4
        rp[.two] = .south
        posRanges.update(rp)
        XCTAssertEqual(posRanges.north[0], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.north[1], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.south[0], Rank.two...Rank.three)
        XCTAssertEqual(posRanges.south[1], Rank.eight...Rank.queen)
        XCTAssertEqual(posRanges.east[0], Rank.three...Rank.nine)
        XCTAssertEqual(posRanges.west[0], Rank.three...Rank.nine)
        XCTAssertEqual(posRanges.west[1], Rank.king...Rank.king)
        XCTAssertEqual(posRanges.north.count, 2)
        XCTAssertEqual(posRanges.south.count, 2)
        XCTAssertEqual(posRanges.east.count, 1)
        XCTAssertEqual(posRanges.west.count, 2)
        XCTAssertFalse(rp.isFull)
        
        // Enough messing around.  Finish layout
        // N:AQ9 E:J75 S:T62 W:K843
        rp[.nine] = .north
        rp[.jack] = .east
        rp[.five] = .east
        rp[.six] = .south
        rp[.eight] = .west
        rp[.three] = .west
        posRanges.update(rp)
        XCTAssertTrue(rp.isFull)
        XCTAssertEqual(posRanges.north[0], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.north[1], Rank.queen...Rank.queen)
        XCTAssertEqual(posRanges.north[2], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.south[0], Rank.two...Rank.two)
        XCTAssertEqual(posRanges.south[1], Rank.six...Rank.six)
        XCTAssertEqual(posRanges.south[2], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.east[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.east[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.east[2], Rank.jack...Rank.jack)
        XCTAssertEqual(posRanges.west[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.west[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.west[2], Rank.king...Rank.king)
        XCTAssertEqual(posRanges.north.count, 3)
        XCTAssertEqual(posRanges.south.count, 3)
        XCTAssertEqual(posRanges.east.count, 3)
        XCTAssertEqual(posRanges.west.count, 3)
        
        
        // Now start removing things and # of ranges shrinks and ranges grow
        // N:A9 E:J75 S:T62 W:K843 (remove Q from N)
        rp[.queen] = nil
        posRanges.update(rp)
        XCTAssertFalse(rp.isFull)
        XCTAssertEqual(posRanges.north[0], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.north[1], Rank.ace...Rank.ace)
        XCTAssertEqual(posRanges.south[0], Rank.two...Rank.two)
        XCTAssertEqual(posRanges.south[1], Rank.six...Rank.six)
        XCTAssertEqual(posRanges.south[2], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.east[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.east[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.east[2], Rank.jack...Rank.king)
        XCTAssertEqual(posRanges.west[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.west[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.west[2], Rank.jack...Rank.king)
        XCTAssertEqual(posRanges.north.count, 2)
        XCTAssertEqual(posRanges.south.count, 3)
        XCTAssertEqual(posRanges.east.count, 3)
        XCTAssertEqual(posRanges.west.count, 3)
        
        // N:9 E:J75 S:T62 W:K843 (remove A from N)
        rp[.ace] = nil
        posRanges.update(rp)
        XCTAssertFalse(rp.isFull)
        XCTAssertEqual(posRanges.north[0], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.south[0], Rank.two...Rank.two)
        XCTAssertEqual(posRanges.south[1], Rank.six...Rank.six)
        XCTAssertEqual(posRanges.south[2], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.east[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.east[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.east[2], Rank.jack...Rank.ace)
        XCTAssertEqual(posRanges.west[0], Rank.three...Rank.five)
        XCTAssertEqual(posRanges.west[1], Rank.seven...Rank.eight)
        XCTAssertEqual(posRanges.west[2], Rank.jack...Rank.ace)
        XCTAssertEqual(posRanges.north.count, 1)
        XCTAssertEqual(posRanges.south.count, 3)
        XCTAssertEqual(posRanges.east.count, 3)
        XCTAssertEqual(posRanges.west.count, 3)

        // N:9 E:J75 S:T2 W:K843 (remove 6 from S)
        rp[.six] = nil
        posRanges.update(rp)
        XCTAssertFalse(rp.isFull)
        XCTAssertEqual(posRanges.north[0], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.south[0], Rank.two...Rank.two)
        XCTAssertEqual(posRanges.south[1], Rank.nine...Rank.ten)
        XCTAssertEqual(posRanges.east[0], Rank.three...Rank.eight)
        XCTAssertEqual(posRanges.east[1], Rank.jack...Rank.ace)
        XCTAssertEqual(posRanges.west[0], Rank.three...Rank.eight)
        XCTAssertEqual(posRanges.west[1], Rank.jack...Rank.ace)
        XCTAssertEqual(posRanges.north.count, 1)
        XCTAssertEqual(posRanges.south.count, 2)
        XCTAssertEqual(posRanges.east.count, 2)
        XCTAssertEqual(posRanges.west.count, 2)
    }
    
    // min and play are closely related, so tested together here.
    func testMinAndPlay() {
        var rp = RankPositions()
        rp[.ace] = .north
        rp[.queen] = .north
        rp[.ten] = .north
        var n = rp.playableRanges(for: .north)
        XCTAssertEqual(n.count, 1)
        XCTAssertEqual(rp.min(in: n[0], for: .north), .ten)
        var p = rp.play(n[0], from: .north)
        XCTAssertEqual(p, .ten)
        n = rp.playableRanges(for: .north)
        p = rp.play(n[0], from: .north)
        XCTAssertEqual(p, .queen)
        n = rp.playableRanges(for: .north)
        p = rp.play(n[0], from: .north)
        XCTAssertEqual(p, .ace)
        XCTAssertTrue(rp.isEmpty)
    }
    
    func testCount() {
        var rp = RankPositions()
        XCTAssertEqual(rp.count(for: .north), 0)
        XCTAssertEqual(rp.count(for: .ew), 0)
        
        rp[.north] = [.ace, .king, .queen]
        rp[.south] = [.two, .three]
        rp[.east] = [.four, .five]
        rp[.west] = [.six]

        XCTAssertEqual(rp.count(for: .north), 3)
        XCTAssertEqual(rp.count(for: .south), 2)
        XCTAssertEqual(rp.count(for: .ns), 5)

        XCTAssertEqual(rp.count(for: .east), 2)
        XCTAssertEqual(rp.count(for: .west), 1)
        XCTAssertEqual(rp.count(for: .ew), 3)
        
    }
}
