//
//  Deal.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

public struct Deal: Codable {
    private var hands = Array<Hand>(repeating: Hand(), count: Position.allCases.count)
    public init() {}
    public subscript(position: Position) -> Hand {
        get {
            return hands[position.rawValue]
        }
        set {
            hands[position.rawValue] = newValue
        }
    }
}
