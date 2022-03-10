//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public struct Deal {
    private var hands = Array<[Card]>(repeating: [], count: Position.allCases.count)
    public subscript(position: Position) -> [Card] {
        get {
            return hands[position.rawValue]
        }
        set {
            hands[position.rawValue] = newValue
        }
    }
}
