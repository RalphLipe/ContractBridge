//
//  EventTest.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/26/24.
//

import XCTest
import ContractBridge

class EventTests: XCTestCase {
    
    func testInit() throws {
        let event = Event()
        
        event.boards.append(Board(number: 1, deal: try Deal(from: "N:AKQJ.AKQ.AKQ.AKQ T98.JT98.JT9.JT9 765.765.8765.876 432.432.432.5432")))
        event.boards.append(Board(number: 2, deal: try Deal(from: "N:AKQJ.AKQ.AKQ.AKQ T98.JT98.JT9.JT9 765.765.8765.876 432.432.432.5432")))
        
        event.pairs.append(Pair(number: 1, direction: .ns, player0: "Ralph", player1: "Lynda"))
        event.pairs.append(Pair(number: 2, direction: .ns, player0: "James", player1: "Claude"))
        event.pairs.append(Pair(number: 1, direction: .ew, player0: "Nicole", player1: "Max"))
        event.pairs.append(Pair(number: 2, direction: .ew, player0: "Gary", player1: "Karina"))
        
        event.boardResults.append(BoardResult(boardNumber: 1, nsPairNumber: 1, ewPairNumber: 2, contract: Contract(level: 3, strain: .noTrump, risk: .undoubled), declarer: .north, score: 400))
     //   event.boardResults.Append(BoardResult()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(event)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Error encoding: \(error)")
        }
        
    }
    
}
