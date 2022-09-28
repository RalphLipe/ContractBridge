//
//  VariableHoldingTests.swift
//  
//
//  Created by Ralph Lipe on 9/27/22.
//

import XCTest
import ContractBridge

class VariableHoldingTests: XCTestCase {

    func rp(_ s: String) -> RankPositions {
        let deal = try! Deal(from: s)
        return RankPositions(hands: deal.hands, suit: .spades)
        
    }
    

    func testInit() throws {
        var vh = VariableHolding(partialHolding: rp("N:AQT8 - 34 -"))
        XCTAssertEqual(vh.combinations, 128)
        var tc = 0
        for ch in vh.combinationHoldings() {
            tc += ch.combinations
            print("\(ch.combinations)")
            for r in ch.ranges {
                print("   \(r.known.rank)   K0 = \(r.known.count0)  K1 = \(r.known.count1)   U0 = \(r.unknownCount0)   U1 = \(r.unknownCount1)")
            }
        }
        XCTAssertEqual(tc, 128)
    }



}
