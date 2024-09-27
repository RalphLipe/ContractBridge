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
        
        event.pairs.append(Pair(number: 1, direction: .ns, player0: "Ralph Lipe", player1: "Lynda Lipe"))
        
     //   event.boardResults.Append(BoardResult()
        let encoder = JSONEncoder()
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
