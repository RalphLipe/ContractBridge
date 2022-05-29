//
//  PBNGameTest.swift
//  
//
//  Created by Ralph Lipe on 5/27/22.
//

import XCTest
import ContractBridge

class PBNGameTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// readFile. Opens a file in the current bundle and return as data
    /// - Parameters:
    ///   - name: fileName
    ///   - withExtension: extension name, i.e. "json"
    /// - Returns: Data of the contents of the file on nil if not found
    static func readFile(_ name: String, withExtension: String) -> String? {
        let bundle = Bundle.module
        guard let url = bundle.path(forResource: name, ofType: withExtension) else { return nil }
        guard let data = try? String(contentsOfFile: url, encoding: .utf8) else { return nil }
        return data
        
        /*
        let bundle = Bundle(for: Self.self)
        if let path = bundle.path(forResource: name, ofType: withExtension) {
            let data = try? Data(contentsOf: URL(fileURLWithPath: path))
            return data
        }
        return nil
         */
    }
    
    func testInit() throws {
        var game = PBNGame()
        game.event = "Has an event"
    }
    
    func testLoad() throws {
        if let data = Self.readFile("SingleGame", withExtension: "pbn") {
            let games = PortableBridgeNotation.load(pbnData: data)
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].board, 1)
            XCTAssertEqual(games[0].dealer, .north)
        } else {
            XCTFail("Couldn't load single game pbn file")
        }
        
        if let data = Self.readFile("MultiGame", withExtension: "pbn") {
            let games = PortableBridgeNotation.load(pbnData: data)
            XCTAssertEqual(games.count, 28)
            // TODO:  Lots more validation here.  Just some randome stuff for now
            XCTAssertEqual(games[4].board, 5)
            XCTAssertEqual(games[4].dealer, .north)
            if let vul = games[4].vulnerable {
                XCTAssertTrue(vul.contains(.ns))
                XCTAssertTrue(vul.contains(.north))
                XCTAssertFalse(vul.contains(.west))
            } else {
                XCTFail("Vulnerable is nil for board 5")
            }
            if let deal = games[4].deal {
                var cards = Array<Card>(deal[.west])
                cards.sortHandOrder()
                XCTAssertEqual(cards[0], .kingOfSpades)
                XCTAssertEqual(cards[1], .fourOfSpades)
                XCTAssertEqual(cards.last!, .fiveOfClubs)
            } else {
                XCTFail("Nil deal for board 5")
            }
            if let dd = games[4].doubleDummyTricks {
                XCTAssertEqual(dd[.north][.diamonds], 9)
                XCTAssertNil(dd[.north][.spades])
                XCTAssertEqual(dd[.south][.noTrump], 7)
                XCTAssertEqual(dd[.west][.spades], 7)
            } else {
                XCTFail("No double dummy data for board 5")
            }
            
            /*
             [Event "#"]
             [Site "#"]
             [Date "#"]
             [Board "5"]
             [Dealer "N"]
             [Vulnerable "NS"]
             [Deal "N:Q95.K2.T7642.J97 JT632.AT764.8.84 A87.9.AQ93.AKQ32 K4.QJ853.KJ5.T65"]
             [DoubleDummyTricks "71199711991791117911"]
             [OptimumResultTable "Declarer;Denomination\2R;Result\2R"]
             */
            
            
        } else {
            XCTFail("Couldn't load multiple game pbn file")
        }
    
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

 

}
