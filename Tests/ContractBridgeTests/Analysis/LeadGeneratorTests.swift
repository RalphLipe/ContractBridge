//
//  LeadPlanGeneratorTests.swift
//  
//
//  Created by Ralph Lipe on 7/30/22.
//

import XCTest
import ContractBridge

class LeadGeneratorTests: XCTestCase {


    func testExample() throws {
        var holding = RankPositions()
        holding[.north] = [.ace, .queen]
        holding[.south] = [.two]
        holding.reassignRanks(from: nil, to: .east)
        let leads = LeadGenerator.generateLeads(rankPositions: holding, pair: .ns, option: .considerAll)
        XCTAssertEqual(leads.count, 4)
    }

    // TODO:  Do some real tests here...
}
