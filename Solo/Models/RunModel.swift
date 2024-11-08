//
//  Item.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit

@Observable
class RunData {
    var runs: [Run] = []
    
    init(runs: [Run]) {
        self.runs = runs
    }
}


@Model
final class Run: Identifiable{
    @Attribute(.unique) public var id: String = UUID().uuidString
    var postedDate: Date
    var startTime: Date
    var endTime: Date
    var elapsedTime: Int            // seconds
    var distanceTraveled: Double    // distance in meters
    var steps: Int
    var startPlacemark: MTPlacemark
    var endPlacemark: MTPlacemark
    var avgSpeed: Double            // miles per hour
    var avgPace: Int                // minutes per mile
    @Attribute(.externalStorage) var routeImage: Data

    
    init(id: String = UUID().uuidString, postedDate:Date, startTime: Date, endTime: Date, elapsedTime: Int, distanceTraveled: Double, steps: Int, startPlacemark: MTPlacemark, endPlacemark: MTPlacemark,  avgSpeed: Double, avgPace: Int, routeImage: Data) {
        self.id = id
        self.postedDate = postedDate
        self.startTime = startTime
        self.endTime = endTime
        self.elapsedTime = elapsedTime
        self.steps = steps
        self.distanceTraveled = distanceTraveled
        self.startPlacemark = startPlacemark
        self.endPlacemark = endPlacemark
        self.avgSpeed = avgSpeed
        self.avgPace = avgPace
        self.routeImage = routeImage
    }
}
