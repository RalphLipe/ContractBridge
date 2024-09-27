//
//  Event.swift
//  ContractBridge
//
//  Created by Ralph Lipe on 9/25/24.
//

import Foundation


public class Event: Codable {
    // This is the top-level object.  It needs:
    public var boards = Array<Board>()
    public var pairs = Array<Pair>()
    public var boardResults = Array<BoardResult>()
}




