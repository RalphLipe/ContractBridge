//
//  MatchPoints.swift
//  
//
//  Created by Ralph Lipe on 3/9/22.
//

import Foundation

class MatchPoints {
    public static func score(scores: [Int]) -> [Int : Float] {
        var matchPoints: [Int : Float] = [:]
        let sortedScores = scores.sorted()
        // Find range of scores that are the same
        // compute total match points / number of same
        var lastScore = sortedScores[0]
        var countSameScore = 1
        var placePoints = 0
        var i = 1
        while i < sortedScores.count {
            if sortedScores[i] == lastScore {
                placePoints += i
                countSameScore += 1
            } else {
                matchPoints[lastScore] = Float(placePoints) / Float(countSameScore)
                countSameScore = 1
                lastScore = sortedScores[i]
                placePoints = i
            }
            i += 1
        }
        matchPoints[lastScore] = Float(placePoints) / Float(countSameScore)
        return matchPoints
    }
}
