//
//  Board.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation
/*
public protocol Initializable {
    init()
}

extension Set: Initializable {}

public struct PositionIndexed<Element: Initializable> {
    private var items: [Element] = Array<Element>(repeating: Element(), count: Position.allCases.count)
    public subscript(position: Position) -> Element {
        get { return items[position.rawValue] }
        set { items[position.rawValue] = newValue }
    }
}

extension String: Initializable {}
*/

/*
 The 15 tag names of the MTS are (in order):
  (1) Event      (the name of the tournament or match)
  (2) Site       (the location of the event)
  (3) Date       (the starting date of the game)
  (4) Board      (the board number)
  (5) West       (the west player)
  (6) North      (the north player)
  (7) East       (the east player)
  (8) South      (the south player)
  (9) Dealer     (the dealer)
 (10) Vulnerable (the situation of vulnerability)
 (11) Deal       (the dealt cards)
 (12) Scoring    (the scoring method)
 (13) Declarer   (the declarer of the contract)
 (14) Contract   (the contract)
 (15) Result     (the result of the game)

 */


public struct PBNGame {
    public init(event: String? = nil, site: String? = nil, date: Date? = nil, board: Int? = nil, players: [Position : String] = [:], dealer: Position? = nil, vulnerable: Vulnerable? = nil, deal: Deal? = nil, scoring: String? = nil, declarer: Position? = nil, contract: Contract? = nil, result: Int? = nil, doubleDummyTricks: DoubleDummyTricks? = nil) {
        self.event = event
        self.site = site
        self.date = date
        self.board = board
        self.players = players
        self.dealer = dealer
        self.vulnerable = vulnerable
        self.deal = deal
        self.scoring = scoring
        self.declarer = declarer
        self.contract = contract
        self.result = result
        self.doubleDummyTricks = doubleDummyTricks
    }
    
    // Required tags
    public var event: String? = nil
    public var site: String? = nil
    public var date: Date? = nil
    public var board: Int? = nil
    public var players: [Position: String] = [:]
    public var dealer: Position? = nil
    public var vulnerable: Vulnerable? = nil
    public var deal: Deal? = nil
    public var scoring: String? = nil // TODO:  Need formal scoring method
    public var declarer: Position? = nil
    public var contract: Contract? = nil
    public var result: Int? = nil

    public var doubleDummyTricks: DoubleDummyTricks? = nil
 
    
    public mutating func parseKeyValue(_ key: String, _ value: String) {
        switch key.lowercased() {
        case "event":
            event = value
        case "site":
            site = value
        case "board":
            board = Int(value)
        case "north", "south", "east", "west":
            players[Position(from: key)!] = value
        case "dealer":
            dealer = Position(from: value)
        case "vulnerable":
            vulnerable = Vulnerable(from: value)
        case "deal":
            deal = try! Deal(from: value)
        case "scoring":
            scoring = value
        case "declarer":
            declarer = Position(from: value)
        case "contract":
            contract = Contract(from: value)
        case "result":
            result = Int(value)
        case "doubledummytricks":
            doubleDummyTricks = DoubleDummyTricks(from: value)
        default: return
        }
    }
    // TODO: Need to escape quotes in string...
    /*
    private func export(_ tag: String, _ value: String?) -> String {
        return "[\(tag) \"\(value)\"]"
    }
    
    public func export() -> [String] {
        var results = [String]()
        results.append(export("evnet", event))
        return results
    }
     */
}


public class PortableBridgeNotation {
    public static func load(pbnData: String) -> [PBNGame] {
        let trimBrackets = CharacterSet(charactersIn: "[]").union(.whitespaces)
        let trimQuotes = CharacterSet(charactersIn: " \"")
        var parsedSomething = false

        
        var games: [PBNGame] = [PBNGame()]
        pbnData.enumerateLines() {
            line, stop in
            if line.trimmingCharacters(in: .whitespaces).count == 0 && parsedSomething {
                // TODO: Check for errors in previous game...
                games.append(PBNGame())
                parsedSomething = false
            }
            let gameIndex = games.count - 1
            if line.starts(with: "[") {
                let trimmedLine = line.trimmingCharacters(in: trimBrackets)
                if let firstSpace = trimmedLine.firstIndex(of: " ") {
                    parsedSomething = true
                    let key = String(trimmedLine[..<firstSpace])
                    let value = String(trimmedLine[firstSpace...]).trimmingCharacters(in: trimQuotes)
                    games[gameIndex].parseKeyValue(key, value)
                }
            }
        }
        if !parsedSomething {
            games.removeLast()
        }
        return games
    }
}


 
