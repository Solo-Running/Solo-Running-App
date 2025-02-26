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

/**
 Model that holds all of a run's statistics
 */
@Model
final class Run: Identifiable{
    public var id: String = UUID().uuidString
    var isDarkMode: Bool = true
    var postedDate: Date = Date()
    var startTime: Date = Date()
    var endTime: Date = Date()
    var elapsedTime: Int  = 0               // seconds
    var distanceTraveled: Double  = 0.0     // distance in meters
    var routeDistance: Double = 0.0
    var steps: Int = 0
    var startPlacemark: MTPlacemark?
    @Relationship(deleteRule: .noAction) var endPlacemark: MTPlacemark? // don't delete the endPlacemark. The user should do this manually
    var avgSpeed: Double = 0.0              // miles per hour
    var avgPace: Int  = 0                   // minutes per mile
    @Attribute(.externalStorage) var routeImage: Data?
    var notes: String = ""
    
    init(id: String = UUID().uuidString, isDarkMode: Bool, postedDate:Date, startTime: Date, endTime: Date, elapsedTime: Int, distanceTraveled: Double, routeDistance: Double, steps: Int, startPlacemark: MTPlacemark, endPlacemark: MTPlacemark,  avgSpeed: Double, avgPace: Int, routeImage: Data, notes: String = "") {
        self.id = id
        self.isDarkMode = isDarkMode
        self.postedDate = postedDate
        self.startTime = startTime
        self.endTime = endTime
        self.elapsedTime = elapsedTime
        self.steps = steps
        self.distanceTraveled = distanceTraveled
        self.routeDistance = routeDistance
        self.startPlacemark = startPlacemark
        self.endPlacemark = endPlacemark
        self.avgSpeed = avgSpeed
        self.avgPace = avgPace
        self.routeImage = routeImage
        self.notes = notes
    }
}
