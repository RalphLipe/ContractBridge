//
//  Board.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation


public struct Board: Identifiable {
    
    // TODO:  I think this is wrong -- Not identifiable...
    public var id: Int {
        boardNumber
    }
    private var playerNames = Array<String?>(repeating: nil, count: Position.allCases.count)
    private var dd = Array<[Int?]>(repeating: Array<Int?>(repeating: nil, count: Strain.allCases.count),
                                count: Position.allCases.count)
    public var boardNumber: Int = 0
    public var dealer: Position = .north
    public var vulnerablility: Vulnerability = []
    public var deal: Deal = Deal()
    public func playerName(_ position: Position) -> String? {
        return playerNames[position.rawValue]
    }
    public mutating func setPlayerName(_ position: Position, _ name: String?) {
        playerNames[position.rawValue] = name
    }
    public func doubleDummy(_ position: Position, _ strain: Strain) -> Int? {
        return dd[position.rawValue][strain.rawValue]
    }
    public func doubleDummy(_ position: Position) -> [Int?] {
        return dd[position.rawValue]
    }
    public mutating func setDoubleDummy(_ position: Position, _ strain: Strain, _ value: Int?) {
        assert(value == nil || (value! >= 0 && value! <= 13))
        dd[position.rawValue][strain.rawValue] = value
    }
}