//
//  ContractTests.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class ContractTests: XCTestCase {


    func testExample() throws {
        let contract = Contract(level: 4, strain: .hearts, penalty: .undoubled, declarer: .north)
        XCTAssertEqual(contract.score(vulnerability: [], tricksTaken: 10), 420)
        XCTAssertEqual(contract.score(vulnerability: [.ns], tricksTaken: 10), 620)
        XCTAssertEqual(contract.score(vulnerability: [], tricksTaken: 9), -50)
        XCTAssertEqual(contract.score(vulnerability: [.ns, .ew], tricksTaken: 8), -200)
        
        let slam = Contract(level: 6, strain: .spades, penalty: .undoubled, declarer: .east)
        XCTAssertEqual(slam.score(vulnerability: [.ew], tricksTaken: 12), 1430)
    }



}
