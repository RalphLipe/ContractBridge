//
//  DoubleDummyMakes.swift
//  
//
//  Created by Ralph Lipe on 5/27/22.
//

import Foundation


public struct DoubleDummyMakes {
    var makes: Dictionary<Position, Dictionary<Strain, Int>>
    
    public init() {
        makes = [:]
        Position.allCases.forEach { makes[$0] = Dictionary<Strain, Int>() }
    }
    
    public init?(from: String) {
        if from.count != Position.allCases.count * Strain.allCases.count { return nil }
        self.init()
        var s = from
        for position: Position in [.north, .south, .east, .west] {
            for strain: Strain in [.noTrump, .spades, .hearts, .diamonds, .clubs] {
                if let m = Int(String(s.removeFirst()), radix: 16) {
                    self[position][strain] = m
                }
            }
        }
    }
    
    public subscript(position: Position) -> Dictionary<Strain, Int> {
        get { return makes[position]! }
        set { makes[position] = newValue }
    }
}
