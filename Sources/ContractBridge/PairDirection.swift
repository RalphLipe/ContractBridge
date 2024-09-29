//
//  PairDirection.swift
//
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation



////////////////
///
import Foundation


public enum PairDirection: Int, CaseIterable, Codable {
    case ns = 0, ew
    
    public init?(from: String) {
        switch from.lowercased() {
        case "ns", "n/s", "north/south": self = .ns;
        case "ew", "e/w", "east/west": self = .ew;
        default: return nil;
        }
    }

    // TODO: DUPLICATED CODE!  TRY TO GET RID OF THIS!
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let value = Self(from: stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot initialize \(Self.self) from invalid String value \(stringValue)")
        }
        self = value
    }
 
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self, style: .character)")
    }
    // TODO: END OF DUPLICATED CODE
    
    public var directions: (Direction, Direction)  {
        switch self {
        case .ns: return (.north, .south)
        case .ew: return (.east, .west)
        }
    }
    public var opponents: PairDirection {
        return self == .ns ? .ew : .ns
    }
}
 
public extension String.StringInterpolation {
    mutating func appendInterpolation(_ pair: PairDirection, style: ContractBridge.Style = .symbol) {
        let directions = pair.directions
        // If asked for "character" style then don't put a / between directions.
        if style == .character {
            appendLiteral("\(directions.0, style: style)\(directions.1, style: style)")
        } else {
            appendLiteral("\(directions.0, style: style)/\(directions.1, style: style)")
        }
    }
}
