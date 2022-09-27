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
        var vh = VariableHolding(partialHolding: rp("N:AQ5 - 234 -"))
        XCTAssertEqual(vh.combinations, 128)
        var tc = 0
        for ch in vh.combinationHoldings() {
            tc += ch.combinations
        }
        XCTAssertEqual(tc, 128)
    }



}
