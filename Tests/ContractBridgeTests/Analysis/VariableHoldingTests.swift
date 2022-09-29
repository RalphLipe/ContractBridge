//
//  VariableHoldingTests.swift
//  
//
//  Created by Ralph Lipe on 9/27/22.
//

import XCTest
import ContractBridge

extension VariableXXX: Equatable {
    public static func == (lhs: VariableXXX, rhs: VariableXXX) -> Bool {
        lhs.unknownCount == rhs.unknownCount && lhs.known == rhs.known
    }
    
    init(_ rank: Rank, ewUnknown: Int, eKnown: Int = 0, wKnown: Int = 0) {
        assert(Pair.ew.positions.0 == .east)
        var k = KnownHoldings(rank: rank, pair: .ew)
        k.count0 = eKnown
        k.count1 = wKnown
        self.init(known: k, unknownCount: ewUnknown)
    }
    init(_ rank: Rank, n: Int, s: Int) {
        assert(Pair.ns.positions.0 == .north)
        var k = KnownHoldings(rank: rank, pair: .ns)
        k.count0 = n
        k.count1 = s
        self.init(known: k, unknownCount: 0)
    }
}


extension XXXCombination: Equatable {
    public static func == (lhs: XXXCombination, rhs: XXXCombination) -> Bool {
        lhs.unknownCount0 == rhs.unknownCount0 && lhs.unknownCount1 == rhs.unknownCount1 && lhs.known == rhs.known
    }

    init(_ rank: Rank, e: Int, w: Int, eKnown: Int = 0, wKnown: Int = 0) {
        assert(Pair.ew.positions.0 == .east)
        var k = KnownHoldings(rank: rank, pair: .ew)
        k.count0 = eKnown
        k.count1 = wKnown
        self.init(known: k, unknownCount0: e, unknownCount1: w)
    }
    init(_ rank: Rank, n: Int, s: Int) {
        assert(Pair.ns.positions.0 == .north)
        var k = KnownHoldings(rank: rank, pair: .ns)
        k.count0 = n
        k.count1 = s
        self.init(known: k)
    }
}

// This is just a test for GitHub.  See if it stays in sync
// And this is just another line... What about this
class VariableHoldingTests: XCTestCase {

    func rp(_ s: String) -> RankPositions {
        let deal = try! Deal(from: s)
        return RankPositions(hands: deal.hands, suit: .spades)
        
    }
    

    enum FindComboError: Error {
        case combinationNotFound
    }
    
    func findCombination(_ comb: [XXXCombination], in vh: VariableHolding) throws -> VariableCombination {
        for c in vh.combinationHoldings() {
            if c.ranges == comb {
                return c
            }
        }
        // TODO: Fail test - throw error?  Something better than this...
        throw FindComboError.combinationNotFound
    }
    
    
    func testAQFinesse() throws {
        let vh = VariableHolding(partialHolding: rp("N:AQ - 23 -"))
        XCTAssertEqual(vh.combinations, 512)
        let expected = [ VariableXXX(.two, n: 0, s: 2),
                         VariableXXX(.jack, ewUnknown: 8),
                         VariableXXX(.queen, n: 1, s: 0),
                         VariableXXX(.king, ewUnknown: 1),
                         VariableXXX(.ace, n: 1, s: 0) ]
        XCTAssertEqual(expected, vh.ranges)
        var tc = 0
        for ch in vh.combinationHoldings() {
            tc += ch.combinations
        }
        XCTAssertEqual(tc, 512)

        let offsideK = [ XXXCombination(.two, n: 0, s: 2),
                         XXXCombination(.jack, e: 4, w: 4),
                         XXXCombination(.queen, n: 1, s: 0),
                         XXXCombination(.king, e: 1, w: 0),
                         XXXCombination(.ace, n: 1, s: 0) ]

        var vc = try! findCombination(offsideK, in: vh)
        
        var pr = PositionRanks()
        pr[.north] = .queen
        pr[.south] = .two
        pr[.east] = .king
        pr[.west] = .jack
        let vhAfterFailedFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedFailedFinesse =
                        [ VariableXXX(.two, n: 0, s: 1),
                         VariableXXX(.king, ewUnknown: 7),
                         VariableXXX(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vhAfterFailedFinesse.ranges)
        
        let onsideK =  [ XXXCombination(.two, n: 0, s: 2),
                         XXXCombination(.jack, e: 4, w: 4),
                         XXXCombination(.queen, n: 1, s: 0),
                         XXXCombination(.king, e: 0, w: 1),
                         XXXCombination(.ace, n: 1, s: 0) ]
        vc = try! findCombination(onsideK, in: vh)
        
        pr[.east] = .jack
        let vhAfterSuccessfulFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedSucceededFinesse = [ VariableXXX(.two, n: 0, s: 1),
                         VariableXXX(.king, ewUnknown: 6, wKnown: 1),
                         VariableXXX(.ace, n: 1, s: 0) ]
        XCTAssertEqual(expectedSucceededFinesse, vhAfterSuccessfulFinesse.ranges)
    }



    // Test of commit
    // Another test
    func testKQFinesse() throws {
        let vh = VariableHolding(partialHolding: rp("N:KQ5 - 234 -"))
        XCTAssertEqual(vh.combinations, 128)
        let expected = [ VariableXXX(.two, n: 1, s: 3),
                         VariableXXX(.jack, ewUnknown: 6),
                         VariableXXX(.king, n: 2, s: 0),
                         VariableXXX(.ace, ewUnknown: 1) ]
        XCTAssertEqual(expected, vh.ranges)
        var tc = 0
        for ch in vh.combinationHoldings() {
            tc += ch.combinations
            print("\(ch.combinations)")
            for r in ch.ranges {
                print("   \(r.known.rank)   K0 = \(r.known.count0)  K1 = \(r.known.count1)   U0 = \(r.unknownCount0)   U1 = \(r.unknownCount1)")
            }
        }
        XCTAssertEqual(tc, 128)

        let offsideA = [ XXXCombination(.two, n: 1, s: 3),
                         XXXCombination(.jack, e: 3, w: 3),
                         XXXCombination(.king, n: 2, s: 0),
                         XXXCombination(.ace, e: 1, w: 0) ]

        var vc = try! findCombination(offsideA, in: vh)
        
        var pr = PositionRanks()
        pr[.north] = .king
        pr[.west] = .jack
        pr[.south] = .two
        pr[.east] = .ace

        let vhAfterFailedFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedFailedFinesse =
                        [ VariableXXX(.two, n: 1, s: 2),
                         VariableXXX(.jack, ewUnknown: 5),
                         VariableXXX(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vhAfterFailedFinesse.ranges)
        
        let onsideA = [ XXXCombination(.two, n: 1, s: 3),
                        XXXCombination(.jack, e: 3, w: 3),
                        XXXCombination(.king, n: 2, s: 0),
                        XXXCombination(.ace, e: 0, w: 1) ]

        vc = try! findCombination(onsideA, in: vh)
        
        pr[.east] = .jack
        
        let vhAfterSuccessfulFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedSucceededFinesse =
                    [ VariableXXX(.two, n: 1, s: 2),
                     VariableXXX(.jack, ewUnknown: 4),
                      VariableXXX(.king, n: 1, s: 0),
                      VariableXXX(.ace, ewUnknown: 0, eKnown:0, wKnown: 1) ]
                    
        XCTAssertEqual(expectedSucceededFinesse, vhAfterSuccessfulFinesse.ranges)
    }

    
    func testDoublieFinesse() throws {
        let vh = VariableHolding(partialHolding: rp("N:AQT - 234 -"))
        XCTAssertEqual(vh.combinations, 128)
        let expected = [ VariableXXX(.two, n: 0, s: 3),
                         VariableXXX(.nine, ewUnknown: 5),
                         VariableXXX(.ten, n: 1, s: 0),
                         VariableXXX(.jack, ewUnknown: 1),
                         VariableXXX(.queen, n: 1, s: 0),
                         VariableXXX(.king, ewUnknown: 1),
                         VariableXXX(.ace, n: 1, s:0) ]
        XCTAssertEqual(expected, vh.ranges)
        var tc = 0
        for ch in vh.combinationHoldings() {
            tc += ch.combinations
            print("\(ch.combinations)")
            for r in ch.ranges {
                print("   \(r.known.rank)   K0 = \(r.known.count0)  K1 = \(r.known.count1)   U0 = \(r.unknownCount0)   U1 = \(r.unknownCount1)")
            }
        }
        XCTAssertEqual(tc, 128)

        let offsideJ = [ XXXCombination(.two, n: 0, s: 3),
                         XXXCombination(.nine, e: 3, w: 2),
                         XXXCombination(.ten, n: 1, s: 0),
                         XXXCombination(.jack, e: 1, w: 0),
                         XXXCombination(.queen, n: 1, s: 0),
                         XXXCombination(.king, e: 0, w: 1),
                         XXXCombination(.ace, n: 1, s: 0) ]

        var vc = try! findCombination(offsideJ, in: vh)
        
        var pr = PositionRanks()
        pr[.south] = .two
        pr[.west] = .nine
        pr[.north] = .ten
        pr[.east] = .jack

        let vhAfterFailedFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedFailedFinesse =
                        [ VariableXXX(.two, n: 0, s: 2),
                          VariableXXX(.jack, ewUnknown: 4),
                          VariableXXX(.queen, n:1, s:0),
                         VariableXXX(.king, ewUnknown: 1),
                         VariableXXX(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vhAfterFailedFinesse.ranges)
        
        let onsideJ = [ XXXCombination(.two, n: 0, s: 3),
                         XXXCombination(.nine, e: 3, w: 2),
                         XXXCombination(.ten, n: 1, s: 0),
                         XXXCombination(.jack, e: 0, w: 1),
                         XXXCombination(.queen, n: 1, s: 0),
                         XXXCombination(.king, e: 1, w: 0),
                         XXXCombination(.ace, n: 1, s: 0) ]
        
        vc = try! findCombination(onsideJ, in: vh)
        pr[.east] = .king
        
        
        let vhAfterSuccessfulFinesse = vc.play(leadPosition: .south, play: pr)
        
        let expectedSucceededFinesse =
                    [ VariableXXX(.two, n: 0, s: 2),
                      VariableXXX(.jack, ewUnknown: 4, wKnown: 1),
                      VariableXXX(.ace, n: 2, s: 0) ]
        
        XCTAssertEqual(expectedSucceededFinesse, vhAfterSuccessfulFinesse.ranges)
        

        // Now put both the King and Jack onside...
        let onsideJK = [ XXXCombination(.two, n: 0, s: 3),
                         XXXCombination(.nine, e: 3, w: 2),
                         XXXCombination(.ten, n: 1, s: 0),
                         XXXCombination(.jack, e: 0, w: 1),
                         XXXCombination(.queen, n: 1, s: 0),
                         XXXCombination(.king, e: 0, w: 1),
                         XXXCombination(.ace, n: 1, s: 0) ]
        
        vc = try! findCombination(onsideJK, in: vh)
        pr[.east] = .nine

        let vhAfterDoubleSuccess = vc.play(leadPosition: .south, play: pr)
        
        let expectedDouleSuccess =
        [ VariableXXX(.two, n: 0, s: 2),
          VariableXXX(.jack, ewUnknown: 3, wKnown: 1),
          VariableXXX(.queen, n: 1, s:0),
          VariableXXX(.king, ewUnknown: 0, wKnown: 1),
          VariableXXX(.ace, n: 1, s: 0) ]

        XCTAssertEqual(expectedDouleSuccess, vhAfterDoubleSuccess.ranges)
        
        
    }
    
}
