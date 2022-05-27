//
//  ContractTests.swift
//  
//
//  Created by Ralph Lipe on 5/18/22.
//

import XCTest
import ContractBridge

class ContractTests: XCTestCase {

    func testInit() throws {
        let threeNT = Contract(from: "3NT")!
        XCTAssertEqual(threeNT.level, 3)
        XCTAssertEqual(threeNT.strain, .noTrump)
        XCTAssertEqual(threeNT.risk, .undoubled)
        
        let zeroLevel = Contract(from: "0NT")
        XCTAssertNil(zeroLevel)
        
        let eightLevel = Contract(from: "8NT")
        XCTAssertNil(eightLevel)
        
        let fourSpadesX = Contract(from: "4SX")!
        XCTAssertEqual(fourSpadesX.level, 4)
        XCTAssertEqual(fourSpadesX.strain, .spades)
        XCTAssertEqual(fourSpadesX.risk, .doubled)

        let sevenDiamondsXX = Contract(from: "7dxx")!
        XCTAssertEqual(sevenDiamondsXX.level, 7)
        XCTAssertEqual(sevenDiamondsXX.strain, .diamonds)
        XCTAssertEqual(sevenDiamondsXX.risk, .redoubled)

        let threeNTXX = Contract(from: "3nTxX")!
        XCTAssertEqual(threeNTXX.level, 3)
        XCTAssertEqual(threeNTXX.strain, .noTrump)
        XCTAssertEqual(threeNTXX.risk, .redoubled)
    }

    func testScore() throws {
        let contract = Contract(level: 4, strain: .hearts, risk: .undoubled)
        XCTAssertEqual(contract.score(isVulnerable: false, tricksTaken: 10), 420)
        XCTAssertEqual(contract.score(isVulnerable: true, tricksTaken: 10), 620)
        XCTAssertEqual(contract.score(isVulnerable: false, tricksTaken: 9), -50)
        XCTAssertEqual(contract.score(isVulnerable: Vulnerable.all.contains(.ns), tricksTaken: 8), -200)
        
        let slam = Contract(level: 6, strain: .spades, risk: .undoubled)
        XCTAssertEqual(slam.score(isVulnerable: Vulnerable.ew.contains(.east), tricksTaken: 12), 1430)
        XCTAssertEqual(slam.score(isVulnerable: true, tricksTaken: 10), -200)
        
        let grandSlam = Contract(level: 7, strain: .noTrump, risk: .doubled)
        XCTAssertEqual(grandSlam.score(isVulnerable: true, tricksTaken: 13), 2490)
        XCTAssertEqual(grandSlam.score(isVulnerable: Vulnerable.ew.contains(.south), tricksTaken: 13), 1790)
        XCTAssertEqual(grandSlam.score(isVulnerable: false, tricksTaken: 10), -500)
        XCTAssertEqual(grandSlam.score(isVulnerable: true, tricksTaken: 10), -800)
        XCTAssertEqual(grandSlam.score(isVulnerable: true, tricksTaken: 0), -3800)
        
        let minor = Contract(level: 5, strain: .diamonds, risk: .undoubled)
        XCTAssertEqual(minor.score(isVulnerable: true, tricksTaken: 11), 600)
        XCTAssertEqual(minor.score(isVulnerable: true, tricksTaken: 12), 620)
        XCTAssertEqual(minor.score(isVulnerable: true, tricksTaken: 13), 640)
        
        let partScore = Contract(level: 2, strain: .spades, risk: .undoubled)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 7), -100)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 8), 110)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 9), 140)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 10), 170)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 11), 200)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 12), 230)
        XCTAssertEqual(partScore.score(isVulnerable: true, tricksTaken: 13), 260)
        
        let doubled = Contract(level: 3, strain: .spades, risk: .doubled)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 0), -2300)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 1), -2000)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 2), -1700)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 3), -1400)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 4), -1100)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 5), -800)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 6), -500)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 7), -300)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 8), -100)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 9),  530)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 10), 630)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 11), 730)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 12), 830)
        XCTAssertEqual(doubled.score(isVulnerable: false, tricksTaken: 13), 930)

        
        let redoubled = Contract(level: 3, strain: .spades, risk: .redoubled)
        XCTAssertEqual(redoubled.score(isVulnerable: false, tricksTaken: 9),  760)
        XCTAssertEqual(redoubled.score(isVulnerable: false, tricksTaken: 10), 960)
        XCTAssertEqual(redoubled.score(isVulnerable: false, tricksTaken: 11), 1160)
        XCTAssertEqual(redoubled.score(isVulnerable: false, tricksTaken: 12), 1360)
        XCTAssertEqual(redoubled.score(isVulnerable: false, tricksTaken: 13), 1560)
        
        
        let redoubledMinor = Contract(level: 2, strain: .diamonds, risk: .redoubled)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 0), -4600)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 1), -4000)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 2), -3400)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 3), -2800)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 4), -2200)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 5), -1600)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 6), -1000)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 7), -400)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 8),  760)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 9),  1160)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 10), 1560)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 11), 1960)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 12), 2360)
        XCTAssertEqual(redoubledMinor.score(isVulnerable: true, tricksTaken: 13), 2760)
    }



}
