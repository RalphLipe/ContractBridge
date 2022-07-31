//
//  CountedCardRange.swift
//  
//
//  Created by Ralph Lipe on 4/18/22.
//

import Foundation

public typealias RankRange = ClosedRange<Rank>

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ rankRange: ClosedRange<Rank>, style: ContractBridge.Style = .symbol) {
        appendLiteral(rankRange.lowerBound == rankRange.upperBound ? "\(rankRange.lowerBound, style: style)" : "\(rankRange.lowerBound, style: style)...\(rankRange.upperBound, style: style)")
    }
}

