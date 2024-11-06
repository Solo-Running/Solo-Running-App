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
class CustomPinLocation: Identifiable {
    
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String?
    var thoroughfare: String?
    var subThoroughfare: String?
    var locality: String?
    var subLocality: String?
    var administrativeArea: String?
    var subAdministrativeArea: String?
    var postalCode: String?
    var country: String?
    var isoCountryCode: String?
    var latitude: Double
    var longitude: Double
    
    init(id: String = UUID().uuidString,
         name: String? = "",
         thoroughfare: String? = "",
         subThoroughfare: String? = "",
         locality: String? = "",
         subLocality: String? = "",
         administrativeArea: String? = "",
         subAdministrativeArea: String? = "",
         postalCode: String? = "",
         country: String? = "",
         isoCountryCode: String? = "",
         longitude: Double,
         latitude: Double
    ) {
         
        self.id = id
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
        self.longitude = longitude
        self.latitude = latitude
    }
}


@Model
class Location {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String?
    var thoroughfare: String?
    var subThoroughfare: String?
    var locality: String?
    var subLocality: String?
    var administrativeArea: String?
    var subAdministrativeArea: String?
    var postalCode: String?
    var country: String?
    var isoCountryCode: String?
    var latitude: Double
    var longitude: Double
    
    init(id: String = UUID().uuidString,
         name: String? = "",
         thoroughfare: String? = "",
         subThoroughfare: String? = "",
         locality: String? = "",
         subLocality: String? = "",
         administrativeArea: String? = "",
         subAdministrativeArea: String? = "",
         postalCode: String? = "",
         country: String? = "",
         isoCountryCode: String? = "",
         longitude: Double,
         latitude: Double
    ) {
         
        self.id = id
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
        self.longitude = longitude
        self.latitude = latitude
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
    var startLocation: Location
    var endLocation: Location
    var avgSpeed: Double            // miles per hour
    var avgPace: Int                // minutes per mile
    @Attribute(.externalStorage) var routeImage: Data

    
    init(id: String = UUID().uuidString, postedDate:Date, startTime: Date, endTime: Date, elapsedTime: Int, distanceTraveled: Double, steps: Int, startLocation: Location, endLocation: Location,  avgSpeed: Double, avgPace: Int, routeImage: Data) {
        self.id = id
        self.postedDate = postedDate
        self.startTime = startTime
        self.endTime = endTime
        self.elapsedTime = elapsedTime
        self.steps = steps
        self.distanceTraveled = distanceTraveled
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.avgSpeed = avgSpeed
        self.avgPace = avgPace
        self.routeImage = routeImage
    }
}
