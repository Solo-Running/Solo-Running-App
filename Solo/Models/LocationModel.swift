//
//  LocationModel.swift
//  Solo
//
//  Created by William Kim on 11/6/24.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit

/**
 Model used to encoding any location into a consistent data structure for displaying placemarks on the map
 */
@Model
class MTPlacemark {
    public var id: String = UUID().uuidString
    var name: String = ""
    var thoroughfare: String = ""
    var subThoroughfare: String = ""
    var locality: String = ""
    var subLocality: String = ""
    var administrativeArea: String = ""
    var subAdministrativeArea: String = ""
    var postalCode: String = ""
    var country: String = ""
    var isoCountryCode: String = ""
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    var isCustomLocation: Bool = false
    var timestamp: Date = Date()
    
    init(id: String = UUID().uuidString,
         name: String = "", 
         thoroughfare: String = "",
         subThoroughfare: String = "",
         locality: String = "",
         subLocality: String = "",
         administrativeArea: String = "",
         subAdministrativeArea: String = "",
         postalCode: String = "",
         country: String = "",
         isoCountryCode: String = "",
         longitude: Double = 0.0,
         latitude: Double = 0.0,
         isCustomLocation: Bool = false,
         timestamp: Date = Date()
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
        self.isCustomLocation = isCustomLocation
        self.timestamp = timestamp
    }
    
    // Method to get CLLocationCoordinate2D for start placemark
    func getLocation() -> CLLocationCoordinate2D {
      return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
    
    // Returns a copy of the placemarks name
    func getName() -> String {
        let copy = MTPlacemark()
        copy.name = name
        return copy.name
    }        
}


@Model
class Location {
    var id: String = UUID().uuidString
    var name: String = ""
    var thoroughfare: String = ""
    var subThoroughfare: String = ""
    var locality: String = ""
    var subLocality: String = ""
    var administrativeArea: String = ""
    var subAdministrativeArea: String = ""
    var postalCode: String = ""
    var country: String = ""
    var isoCountryCode: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    init(id: String = UUID().uuidString,
         name: String = "",
         thoroughfare: String = "",
         subThoroughfare: String = "",
         locality: String = "",
         subLocality: String = "" ,
         administrativeArea: String = "",
         subAdministrativeArea: String = "" ,
         postalCode: String = "",
         country: String = "",
         isoCountryCode: String = "",
         longitude: Double = 0.0,
         latitude: Double = 0.0
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
