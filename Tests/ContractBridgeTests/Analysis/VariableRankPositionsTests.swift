//
//  VariableRankPositionsTests.swift
//  
//
//  Created by Ralph Lipe on 9/27/22.
//

import XCTest
import ContractBridge


extension VariableRankPositions.Bracket {
    init(_ rank: Rank, ewUnknown: Int, eKnown: Int = 0, wKnown: Int = 0) {
        var pc = VariableRankPositions.PairCounts()
        pc[.east] = eKnown
        pc[.west] = wKnown
        self.init(pair: .ew, upperBound: rank, known: pc, unknownCount: ewUnknown)
    }
    init(_ rank: Rank, n: Int, s: Int) {
        var pc = VariableRankPositions.PairCounts()
        pc[.north] = n
        pc[.south] = s
        self.init(pair: .ns, upperBound: rank, known: pc, unknownCount: 0)
    }
}


extension VariableRankPositions.Variant.Bracket {
    init(_ rank: Rank, e: Int, w: Int, eKnown: Int = 0, wKnown: Int = 0) {
        var known = VariableRankPositions.PairCounts()
        var unknown = VariableRankPositions.PairCounts()
        known[.east] = eKnown
        known[.west] = wKnown
        unknown[.east] = e
        unknown[.west] = w
        self.init(pair: .ew, upperBound: rank, known: known, unknown: unknown)
    }
    init(_ rank: Rank, n: Int, s: Int) {
        var known = VariableRankPositions.PairCounts()
        known[.north] = n
        known[.south] = s
        self.init(pair: .ns, upperBound: rank, known: known, unknown: VariableRankPositions.PairCounts())
    }
}


class VariableRankPositionsTest: XCTestCase {
 
    func rp(_ s: String) -> RankPositions {
        let deal = try! Deal(from: s)
        return RankPositions(hands: deal.hands, suit: .spades)
        
    }
    
    
    enum FindVariantError: Error {
        case variantNotFound
    }
    
    func findVariant(_ brackets: [VariableRankPositions.Variant.Bracket], in vrp: VariableRankPositions) throws -> VariableRankPositions.Variant {
        for v in vrp.variants {
            if v.brackets == brackets {
                return v
            }
        }
        // TODO: Fail test - throw error?  Something better than this...
        throw FindVariantError.variantNotFound
    }
    
    func playCombo(_ v: VariableRankPositions.Variant) {
        var play = PositionRanks()
        for p in Direction.allCases {
            let ranks = v.ranks(for: p)
            if let r = ranks.max() {
                play[p] = r
            }
        }
        let vNext = v.play(leadPosition: .south, play: play, finesseInferences: false)
        playAll(VariableRankPositions(from: vNext))
    }
    
    
    func playAll(_ vrp: VariableRankPositions) {
        if !vrp.brackets.isEmpty {    // TODO: Add isEmpty
            var totalCombos = 0
            for v in vrp.variants {
                totalCombos += v.combinations
                playCombo(v)
                if totalCombos > vrp.combinations {
                    print("OUTHCC")
                }
            }

            XCTAssertEqual(totalCombos, vrp.combinations)
        }
    }
    
    
//    func printvrp(_ vrp: VariableRankPositions) {
//        print("\(vrp.brackets.count) brackets have \(vrp.combinations):")
//        for r in vrp.brackets {
//            print("   \(r.known.rank) \(r.pair) k=\(r.known.count0),\(r.known.count1) u=\(r.unknownCount)")
//        }
//    }
    
    
    // NOTE:  A simple test of brackets that can not be inferred to have known holdings
    // are the only thing that work for this test.

    func testPlayAllCombos() throws {
        var vrp = VariableRankPositions(partialHolding: rp("N:AQ - 2467 -"))
        XCTAssertEqual(vrp.combinations, 128)
        playAll(vrp)
        vrp = VariableRankPositions(partialHolding: rp("N:- - - -"))
        XCTAssertEqual(vrp.brackets.count, 1)
        XCTAssertEqual(vrp.brackets[0].unknownCount, 13)
        XCTAssertEqual(vrp.brackets[0].pair, .ew)
        XCTAssertEqual(vrp.combinations, 8192)
        playAll(vrp)
        vrp = VariableRankPositions(partialHolding: rp("N:2 - 3 -"))
        XCTAssertEqual(vrp.brackets.count, 2)
        XCTAssertEqual(vrp.brackets[0].count, 2)
        XCTAssertEqual(vrp.brackets[0].pair, .ns)
        XCTAssertEqual(vrp.combinations, 2048)
        playAll(vrp)
        vrp = VariableRankPositions(partialHolding: rp("N:26TA - 48Q -"))
        XCTAssertEqual(vrp.brackets.count, 13)
        XCTAssertEqual(vrp.brackets[0].count, 1)
        XCTAssertEqual(vrp.brackets[0].pair, .ns)
        XCTAssertEqual(vrp.brackets[1].pair, .ew)
        XCTAssertEqual(vrp.combinations, 64)
        playAll(vrp)
    }
    
    
    func testAQFinesse() throws {
        let vrp = VariableRankPositions(partialHolding: rp("N:AQ - 23 -"))
        XCTAssertEqual(vrp.combinations, 512)
        let expected = [ VariableRankPositions.Bracket(.three, n: 0, s: 2),
                         VariableRankPositions.Bracket(.jack, ewUnknown: 8),
                         VariableRankPositions.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Bracket(.king, ewUnknown: 1),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        XCTAssertEqual(expected, vrp.brackets)
        var tc = 0
        for v in vrp.variants {
            tc += v.combinations
        }
        XCTAssertEqual(tc, 512)

        let offsideK = [ VariableRankPositions.Variant.Bracket(.three, n: 0, s: 2),
                         VariableRankPositions.Variant.Bracket(.jack, e: 4, w: 4),
                         VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.king, e: 1, w: 0),
                         VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]

        var vc = try! findVariant(offsideK, in: vrp)
        
        var pr = PositionRanks()
        pr[.north] = .queen
        pr[.south] = .two
        pr[.east] = .king
        pr[.west] = .jack
        let vrpAfterFailedFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedFailedFinesse =
                        [ VariableRankPositions.Bracket(.three, n: 0, s: 1),
                         VariableRankPositions.Bracket(.king, ewUnknown: 7),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vrpAfterFailedFinesse.brackets)
        
        let onsideK =  [ VariableRankPositions.Variant.Bracket(.three, n: 0, s: 2),
                         VariableRankPositions.Variant.Bracket(.jack, e: 4, w: 4),
                         VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.king, e: 0, w: 1),
                         VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]
        vc = try! findVariant(onsideK, in: vrp)
        
        pr[.east] = .jack
        let vrpAfterSuccessfulFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedSucceededFinesse = [ VariableRankPositions.Bracket(.three, n: 0, s: 1),
                         VariableRankPositions.Bracket(.king, ewUnknown: 6, wKnown: 1),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        XCTAssertEqual(expectedSucceededFinesse, vrpAfterSuccessfulFinesse.brackets)
    }



    func testKQFinesse() throws {
        let vrp = VariableRankPositions(partialHolding: rp("N:KQ5 - 234 -"))
        XCTAssertEqual(vrp.combinations, 128)
        let expected = [ VariableRankPositions.Bracket(.five, n: 1, s: 3),
                         VariableRankPositions.Bracket(.jack, ewUnknown: 6),
                         VariableRankPositions.Bracket(.king, n: 2, s: 0),
                         VariableRankPositions.Bracket(.ace, ewUnknown: 1) ]
        XCTAssertEqual(expected, vrp.brackets)
        var tc = 0
        for ch in vrp.variants {
            tc += ch.combinations
 
        }
        XCTAssertEqual(tc, 128)

        let offsideA = [ VariableRankPositions.Variant.Bracket(.five, n: 1, s: 3),
                         VariableRankPositions.Variant.Bracket(.jack, e: 3, w: 3),
                         VariableRankPositions.Variant.Bracket(.king, n: 2, s: 0),
                         VariableRankPositions.Variant.Bracket(.ace, e: 1, w: 0) ]

        var vc = try! findVariant(offsideA, in: vrp)
        
        var pr = PositionRanks()
        pr[.north] = .king
        pr[.west] = .jack
        pr[.south] = .two
        pr[.east] = .ace

        let vrpAfterFailedFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedFailedFinesse =
                        [ VariableRankPositions.Bracket(.five, n: 1, s: 2),
                         VariableRankPositions.Bracket(.jack, ewUnknown: 5),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vrpAfterFailedFinesse.brackets)
        
        let onsideA = [ VariableRankPositions.Variant.Bracket(.five, n: 1, s: 3),
                        VariableRankPositions.Variant.Bracket(.jack, e: 3, w: 3),
                        VariableRankPositions.Variant.Bracket(.king, n: 2, s: 0),
                        VariableRankPositions.Variant.Bracket(.ace, e: 0, w: 1) ]

        vc = try! findVariant(onsideA, in: vrp)
        
        pr[.east] = .jack
        
        let vrpAfterSuccessfulFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedSucceededFinesse =
                    [ VariableRankPositions.Bracket(.five, n: 1, s: 2),
                     VariableRankPositions.Bracket(.jack, ewUnknown: 4),
                      VariableRankPositions.Bracket(.king, n: 1, s: 0),
                      VariableRankPositions.Bracket(.ace, ewUnknown: 0, eKnown:0, wKnown: 1) ]
                    
        XCTAssertEqual(expectedSucceededFinesse, vrpAfterSuccessfulFinesse.brackets)
    }

 
    func testDoublieFinesse() throws {
        let vrp = VariableRankPositions(partialHolding: rp("N:AQT - 234 -"))
        XCTAssertEqual(vrp.combinations, 128)
        let expected = [ VariableRankPositions.Bracket(.four, n: 0, s: 3),
                         VariableRankPositions.Bracket(.nine, ewUnknown: 5),
                         VariableRankPositions.Bracket(.ten, n: 1, s: 0),
                         VariableRankPositions.Bracket(.jack, ewUnknown: 1),
                         VariableRankPositions.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Bracket(.king, ewUnknown: 1),
                         VariableRankPositions.Bracket(.ace, n: 1, s:0) ]
        XCTAssertEqual(expected, vrp.brackets)
        var tc = 0
        for v in vrp.variants {
            tc += v.combinations
        }
        XCTAssertEqual(tc, 128)

        let offsideJ = [ VariableRankPositions.Variant.Bracket(.four, n: 0, s: 3),
                         VariableRankPositions.Variant.Bracket(.nine, e: 3, w: 2),
                         VariableRankPositions.Variant.Bracket(.ten, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.jack, e: 1, w: 0),
                         VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.king, e: 0, w: 1),
                         VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]

        var vc = try! findVariant(offsideJ, in: vrp)
        
        var pr = PositionRanks()
        pr[.south] = .two
        pr[.west] = .nine
        pr[.north] = .ten
        pr[.east] = .jack

        let vrpAfterFailedFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedFailedFinesse =
                        [ VariableRankPositions.Bracket(.four, n: 0, s: 2),
                          VariableRankPositions.Bracket(.jack, ewUnknown: 4),
                          VariableRankPositions.Bracket(.queen, n:1, s:0),
                         VariableRankPositions.Bracket(.king, ewUnknown: 1),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedFailedFinesse, vrpAfterFailedFinesse.brackets)
        
        let onsideJ = [ VariableRankPositions.Variant.Bracket(.four, n: 0, s: 3),
                         VariableRankPositions.Variant.Bracket(.nine, e: 3, w: 2),
                         VariableRankPositions.Variant.Bracket(.ten, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.jack, e: 0, w: 1),
                         VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.king, e: 1, w: 0),
                         VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]
        
        vc = try! findVariant(onsideJ, in: vrp)
        pr[.east] = .king
        
        
        let vrpAfterSuccessfulFinesse = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedSucceededFinesse =
                    [ VariableRankPositions.Bracket(.four, n: 0, s: 2),
                      VariableRankPositions.Bracket(.jack, ewUnknown: 4, wKnown: 1),
                      VariableRankPositions.Bracket(.ace, n: 2, s: 0) ]
        
        XCTAssertEqual(expectedSucceededFinesse, vrpAfterSuccessfulFinesse.brackets)
        

        // Now put both the King and Jack onside...
        let onsideJK = [ VariableRankPositions.Variant.Bracket(.four, n: 0, s: 3),
                         VariableRankPositions.Variant.Bracket(.nine, e: 3, w: 2),
                         VariableRankPositions.Variant.Bracket(.ten, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.jack, e: 0, w: 1),
                         VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 0),
                         VariableRankPositions.Variant.Bracket(.king, e: 0, w: 1),
                         VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]
        
        vc = try! findVariant(onsideJK, in: vrp)
        pr[.east] = .nine

        let vrpAfterDoubleSuccess = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedDouleSuccess =
            [   VariableRankPositions.Bracket(.four, n: 0, s: 2),
                VariableRankPositions.Bracket(.jack, ewUnknown: 3, wKnown: 1),
                VariableRankPositions.Bracket(.queen, n: 1, s:0),
                VariableRankPositions.Bracket(.king, ewUnknown: 0, wKnown: 1),
                VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedDouleSuccess, vrpAfterDoubleSuccess.brackets)
    }
    

    func testShowsOut() throws {
        let vrp = VariableRankPositions(partialHolding: rp("N:AQ4 - 23J -"))
        XCTAssertEqual(vrp.combinations, 128)
        let expected = [ VariableRankPositions.Bracket(.four, n: 1, s: 2),
                         VariableRankPositions.Bracket(.ten, ewUnknown: 6),
                         VariableRankPositions.Bracket(.queen, n: 1, s: 1),
                         VariableRankPositions.Bracket(.king, ewUnknown: 1),
                         VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        XCTAssertEqual(expected, vrp.brackets)
        let eastOut = [ VariableRankPositions.Variant.Bracket(.four, n: 1, s: 2),
                        VariableRankPositions.Variant.Bracket(.ten, e: 0, w: 6),
                        VariableRankPositions.Variant.Bracket(.queen, n: 1, s: 1),
                        VariableRankPositions.Variant.Bracket(.king, e: 0, w: 1),
                        VariableRankPositions.Variant.Bracket(.ace, n: 1, s: 0) ]

        let vc = try! findVariant(eastOut, in: vrp)
        
        var pr = PositionRanks()
        pr[.north] = .queen
        pr[.south] = .two
        pr[.east] = nil
        pr[.west] = .ten
        let vrpAfterEastShowsOut = VariableRankPositions(from: vc.play(leadPosition: .south, play: pr))
        
        let expectedKnownInWest =
                        [ VariableRankPositions.Bracket(.four, n: 1, s: 1),
                          VariableRankPositions.Bracket(.ten, ewUnknown: 0, wKnown: 5),
                          VariableRankPositions.Bracket(.queen, n: 0, s: 1),
                          VariableRankPositions.Bracket(.king, ewUnknown: 0, wKnown: 1),
                          VariableRankPositions.Bracket(.ace, n: 1, s: 0) ]
        
        XCTAssertEqual(expectedKnownInWest, vrpAfterEastShowsOut.brackets)
    }

    
}
