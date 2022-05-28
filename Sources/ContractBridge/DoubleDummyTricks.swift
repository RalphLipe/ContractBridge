//
//  DoubleDummyTricks.swift
//  
//
//  Created by Ralph Lipe on 5/27/22.
//

import Foundation


public struct DoubleDummyTricks {
    var makes: Dictionary<Position, Dictionary<Strain, Int>>
    
    public init() {
        makes = [:]
        Position.allCases.forEach { makes[$0] = Dictionary<Strain, Int>() }
    }
    
    public init?(from: String) {
        if from.count != Position.allCases.count * Strain.allCases.count { return nil }
        self.init()
        var s = from
        var allNonMakingAreOne = true
        for position: Position in [.north, .south, .east, .west] {
            for strain: Strain in [.noTrump, .spades, .hearts, .diamonds, .clubs] {
                if let m = Int(String(s.removeFirst()), radix: 16) {
                    self[position][strain] = m
                    if m < 7 && m != 1 { allNonMakingAreOne = false }
                }
            }
        }
        // If every contract that makes less than 7 is shown as making exactly 1 trick then
        // this is bogus data.  Set all the 1's to nil by filtering them out.
        if allNonMakingAreOne {
            for position: Position in Position.allCases {
                self[position] = self[position].filter { $1 != 1 }
            }
        }
    }
    
    public subscript(position: Position) -> Dictionary<Strain, Int> {
        get { return makes[position]! }
        set { makes[position] = newValue }
    }
}
