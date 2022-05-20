//
//  ContractTests.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class ContractTests: XCTestCase {


    func testScore() throws {
        let contract = Contract(level: 4, strain: .hearts, penalty: .undoubled, declarer: .north)
        XCTAssertEqual(contract.score(vulnerability: [], tricksTaken: 10), 420)
        XCTAssertEqual(contract.score(vulnerability: [.ns], tricksTaken: 10), 620)
        XCTAssertEqual(contract.score(vulnerability: [], tricksTaken: 9), -50)
        XCTAssertEqual(contract.score(vulnerability: [.ns, .ew], tricksTaken: 8), -200)
        
        let slam = Contract(level: 6, strain: .spades, penalty: .undoubled, declarer: .east)
        XCTAssertEqual(slam.score(vulnerability: [.ew], tricksTaken: 12), 1430)
        XCTAssertEqual(slam.score(vulnerability: [.ew], tricksTaken: 10), -200)
        
        let grandSlam = Contract(level: 7, strain: .noTrump, penalty: .doubled, declarer: .south)
        XCTAssertEqual(grandSlam.score(vulnerability: [.ns], tricksTaken: 13), 2490)
        XCTAssertEqual(grandSlam.score(vulnerability: [.ew], tricksTaken: 13), 1790)
        XCTAssertEqual(grandSlam.score(vulnerability: [.ew], tricksTaken: 10), -500)
        XCTAssertEqual(grandSlam.score(vulnerability: [.ns, .ew], tricksTaken: 10), -800)
        XCTAssertEqual(grandSlam.score(vulnerability: [.ns, .ew], tricksTaken: 0), -3800)
        
        let minor = Contract(level: 5, strain: .diamonds, penalty: .undoubled, declarer: .north)
        XCTAssertEqual(minor.score(vulnerability: [.ns, .ew], tricksTaken: 11), 600)
        XCTAssertEqual(minor.score(vulnerability: [.ns, .ew], tricksTaken: 12), 620)
        XCTAssertEqual(minor.score(vulnerability: [.ns, .ew], tricksTaken: 13), 640)
        
        let partScore = Contract(level: 2, strain: .spades, penalty: .undoubled, declarer: .west)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 7), -100)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 8), 110)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 9), 140)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 10), 170)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 11), 200)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 12), 230)
        XCTAssertEqual(partScore.score(vulnerability: [.ns, .ew], tricksTaken: 13), 260)
        
        let doubled = Contract(level: 3, strain: .spades, penalty: .doubled, declarer: .north)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 0), -2300)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 1), -2000)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 2), -1700)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 3), -1400)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 4), -1100)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 5), -800)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 6), -500)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 7), -300)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 8), -100)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 9),  530)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 10), 630)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 11), 730)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 12), 830)
        XCTAssertEqual(doubled.score(vulnerability: [], tricksTaken: 13), 930)

        
        let redoubled = Contract(level: 3, strain: .spades, penalty: .redoubled, declarer: .north)
        XCTAssertEqual(redoubled.score(vulnerability: [], tricksTaken: 9),  760)
        XCTAssertEqual(redoubled.score(vulnerability: [], tricksTaken: 10), 960)
        XCTAssertEqual(redoubled.score(vulnerability: [], tricksTaken: 11), 1160)
        XCTAssertEqual(redoubled.score(vulnerability: [], tricksTaken: 12), 1360)
        XCTAssertEqual(redoubled.score(vulnerability: [], tricksTaken: 13), 1560)
        
        
        let redoubledMinor = Contract(level: 2, strain: .diamonds, penalty: .redoubled, declarer: .north)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 0), -4600)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 1), -4000)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 2), -3400)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 3), -2800)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 4), -2200)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 5), -1600)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 6), -1000)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 7), -400)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 8),  760)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 9),  1160)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 10), 1560)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 11), 1960)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 12), 2360)
        XCTAssertEqual(redoubledMinor.score(vulnerability: [.ns], tricksTaken: 13), 2760)
    }



}
