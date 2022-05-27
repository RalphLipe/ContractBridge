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

    public var doubleDummy: Dictionary<Position, Dictionary<Strain, Int>>? = nil
    
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


class PortableBridgeNotation {
    static func load(pbnData: String) -> [PBNGame] {
        let trimBrackets = CharacterSet(charactersIn: "[]").union(.whitespaces)
        let trimQuotes = CharacterSet(charactersIn: " \"")

        
        var games: [PBNGame] = [PBNGame()]
        pbnData.enumerateLines() {
            line, stop in
            if line.trimmingCharacters(in: .whitespaces).count == 0 {
                // TODO: Check for errors in previous game...
                games.append(PBNGame())
            }
            let gameIndex = games.count - 1
            if line.starts(with: "[") {
                let trimmedLine = line.trimmingCharacters(in: trimBrackets)
                if let firstSpace = trimmedLine.firstIndex(of: " ") {
                    let key = String(trimmedLine[..<firstSpace])
                    let value = String(trimmedLine[firstSpace...]).trimmingCharacters(in: trimQuotes)
                    games[gameIndex].parseKeyValue(key, value)
                }
            }
        }
        if games.last!.board == nil {
            games.removeLast()
        }
        return games
    }
}


 

extension PBNGame {
    /*
    init?(pbnData: [String], i: inout Int) {
        self.init()
        let trimBrackets = CharacterSet(charactersIn: "[]").union(.whitespaces)
        let trimQuotes = CharacterSet(charactersIn: " \"")
        while i < pbnData.count && pbnData[i] != "" {
            if pbnData[i].first == "[" {
                let trimmedLine = pbnData[i].trimmingCharacters(in: trimBrackets)
                if let firstSpace = trimmedLine.firstIndex(of: " ") {
                    let key = String(trimmedLine[..<firstSpace])
                    let value = String(trimmedLine[firstSpace...]).trimmingCharacters(in: trimQuotes)
                    parseKeyValue(key, value)
                }
            }
            i += 1
        }
        // Now skip all white space before returning
        while i < pbnData.count && pbnData[i] == "" {
            i += 1
        }
        if self.board == 0 { return nil }
    }
     */
    
    internal mutating func parseKeyValue(_ key: String, _ value: String) {
        switch key.lowercased() {
        case "board":
            board = Int(value)
        case "north", "south", "east", "west":
            players[Position(from: key)!] = value
        case "deal":
            deal = try! Deal(from: value)
        case "dealer":
            dealer = Position(from: value)
        case "vulnerable":
            vulnerable = Vulnerable(value)
        case "doubledummytricks":
            parseDoubleDummy(value)
        default: return
        }
    }
    
    private mutating func parseDoubleDummy(_ value: String) {
        if value.count == Position.allCases.count * Strain.allCases.count {
            var dd: Dictionary<Position, Dictionary<Strain, Int>> = [:]
            Position.allCases.forEach { dd[$0] = Dictionary<Strain, Int>() }
            var makes: [Int] = []
            for char in value {
                if let x = Int(String(char), radix: 16) {
                    makes.append(x)
                } else {
                    makes.append(-1) //BUBBUG
                }
            }
            var i = 0
            for position: Position in [.north, .south, .east, .west] {
                for strain: Strain in [.noTrump, .spades, .hearts, .diamonds, .clubs] {
                    dd[position]![strain] = makes[i]
                    i += 1
                }
            }
            self.doubleDummy = dd
        }
    }
}
