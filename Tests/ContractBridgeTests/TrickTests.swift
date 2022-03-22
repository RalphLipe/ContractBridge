//
//  TrickTests.swift.swift
//  
//
//  Created by Ralph Lipe on 3/21/22.
//

import XCTest
import ContractBridge

class TrickTests: XCTestCase {


    func testUndoPlay() throws {
        var trick = Trick(lead: Card(.nine, .clubs), position: .north, strain: .hearts)
        XCTAssertEqual(trick.winningPosition, .north)
        XCTAssertEqual(trick.winningCard.rank, .nine)
        try! trick.play(card: Card(.ten, .clubs), position: .east)
        XCTAssertEqual(trick.winningPosition, .east)
        try! trick.play(card: Card(.three, .hearts), position: .south)
        XCTAssertEqual(trick.winningCard.suit, .hearts)
        XCTAssertTrue(trick.isTrumped)
        XCTAssertFalse(trick.isComplete)
        XCTAssertEqual(try! trick.undoPlay(), Card(.three, .hearts))
        XCTAssertEqual(trick.winningCard, Card(.ten, .clubs))
        XCTAssertFalse(trick.isTrumped)
        XCTAssertEqual(trick.winningPosition, .east)
        try! trick.play(card: Card(.three, .hearts), position: .south)
        XCTAssertEqual(trick.winningCard.suit, .hearts)
        XCTAssertTrue(trick.isTrumped)
        XCTAssertFalse(trick.isComplete)
        try! trick.play(card: Card(.ace, .hearts), position: .west)
        XCTAssertEqual(trick.winningCard, Card(.ace, .hearts))
        XCTAssertTrue(trick.isTrumped)
        XCTAssertTrue(trick.isComplete)
        XCTAssertEqual(trick.winningPosition, .west)

        XCTAssertEqual(try! trick.undoPlay(), Card(.ace, .hearts))
        XCTAssertEqual(trick.winningCard, Card(.three, .hearts))
        XCTAssertTrue(trick.isTrumped)
        XCTAssertFalse(trick.isComplete)
        XCTAssertEqual(trick.winningPosition, .south)

        XCTAssertEqual(try! trick.undoPlay(), Card(.three, .hearts))
        XCTAssertEqual(trick.winningCard, Card(.ten, .clubs))
        XCTAssertFalse(trick.isTrumped)
        XCTAssertFalse(trick.isComplete)
        XCTAssertEqual(trick.winningPosition, .east)

        XCTAssertEqual(try! trick.undoPlay(), Card(.ten, .clubs))
        XCTAssertEqual(trick.winningCard, Card(.nine, .clubs))
        XCTAssertFalse(trick.isTrumped)
        XCTAssertFalse(trick.isComplete)
        XCTAssertEqual(trick.winningPosition, .north)

        XCTAssertThrowsError(try trick.undoPlay())

    }


}
