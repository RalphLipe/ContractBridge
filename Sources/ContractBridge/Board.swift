//
//  Board.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


struct Board: Identifiable {
    var id: Int {
        boardNumber
    }
    private var playerNames = Array<String?>(repeating: nil, count: Position.allCases.count)
    private var dd = Array<[Int?]>(repeating: Array<Int?>(repeating: nil, count: Strain.allCases.count),
                                count: Position.allCases.count)
    var boardNumber: Int = 0
    var dealer: Position = .north
    var vulnerablility: Vulnerability = []
    var deal: Deal = Deal()
    func playerName(_ position: Position) -> String? {
        return playerNames[position.rawValue]
    }
    mutating func setPlayerName(_ position: Position, _ name: String?) {
        playerNames[position.rawValue] = name
    }
    func doubleDummy(_ position: Position, _ strain: Strain) -> Int? {
        return dd[position.rawValue][strain.rawValue]
    }
    func doubleDummy(_ position: Position) -> [Int?] {
        return dd[position.rawValue]
    }
    mutating func setDoubleDummy(_ position: Position, _ strain: Strain, _ value: Int?) {
        assert(value == nil || (value! >= 0 && value! <= 13))
        dd[position.rawValue][strain.rawValue] = value
    }
}
