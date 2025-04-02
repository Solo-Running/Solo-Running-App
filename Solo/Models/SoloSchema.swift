//
//  UserModel.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit

// Make the models point to latest version
typealias User = SoloSchemaV3.User
typealias Run = SoloSchemaV3.Run
typealias Location = SoloSchemaV3.Location
typealias MTPlacemark = SoloSchemaV3.MTPlacemark
typealias Pace = SoloSchemaV3.Pace

extension Run {
    var month: Int {
        Calendar.current.component(.month, from: postedDate)
    }
    
    var year: Int {
        Calendar.current.component(.year, from: postedDate)
    }
}

// Define Migration plan
// https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema
enum SoloSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SoloSchemaV1.self, SoloSchemaV2.self, SoloSchemaV3.self]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SoloSchemaV1.self,
        toVersion: SoloSchemaV2.self,
        willMigrate: { context in
            // do nothing
        }, didMigrate: nil
    )
    
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SoloSchemaV2.self,
        toVersion: SoloSchemaV3.self,
        willMigrate: { context in
            // do nothing
        }, didMigrate: nil
    )
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }
}


enum SoloSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [User.self, Run.self, Location.self, MTPlacemark.self]
    }
    
    @Model
    public class User {
        public var id: String = UUID().uuidString
        var fullName: String = "User Name"
        var streak: Int = 0
        var streakLastDoneDate: Date?
        @Attribute(.externalStorage) var profilePicture: Data?

        
        init(fullName: String? = "User Name", streak: Int? = 0, streakLastDoneDate: Date? = Date(), profilePicture: Data? = nil) {
            self.fullName = fullName ?? ""
            self.streak = streak ?? 0
            self.streakLastDoneDate = streakLastDoneDate
            self.profilePicture = profilePicture
        }
    }
    
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
        var nameEditDate: Date?
        
        // Cloudkit requires inverse relationships even if you don't use them
        @Relationship(inverse: \Run.startPlacemark) var runsStartingHere: [Run]?
        @Relationship(inverse: \Run.endPlacemark) var runsEndingHere: [Run]?
        
      
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
             timestamp: Date = Date(),
             nameEditDate: Date?
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
            self.nameEditDate = nameEditDate
        }
        
        // Method to get CLLocationCoordinate2D for start placemark
        func getLocation() -> CLLocationCoordinate2D {
          return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        
        // Returns a copy of the placemarks name
        func getName() -> String {
            let copy = MTPlacemark(nameEditDate: nil)
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

}


enum SoloSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [User.self, Run.self, Location.self, MTPlacemark.self, Pace.self]
    }
    
    @Model
    public class User {
        public var id: String = UUID().uuidString
        var fullName: String = "User Name"
        var streak: Int = 0
        var streakLastDoneDate: Date?
        @Attribute(.externalStorage) var profilePicture: Data?

        var longestStreak: Int = 0
        
        init(fullName: String? = "User Name", streak: Int? = 0, streakLastDoneDate: Date? = Date(), profilePicture: Data? = nil, longestStreak: Int? = 0) {
            self.fullName = fullName ?? ""
            self.streak = streak ?? 0
            self.streakLastDoneDate = streakLastDoneDate
            self.profilePicture = profilePicture
            self.longestStreak = longestStreak ?? 0
        }
    }
    
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
        var nameEditDate: Date?
        
        // Cloudkit requires inverse relationships even if you don't use them
        @Relationship(inverse: \Run.startPlacemark) var runsStartingHere: [Run]?
        @Relationship(inverse: \Run.endPlacemark) var runsEndingHere: [Run]?
        
      
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
             timestamp: Date = Date(),
             nameEditDate: Date?
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
            self.nameEditDate = nameEditDate
        }
        
        // Method to get CLLocationCoordinate2D for start placemark
        func getLocation() -> CLLocationCoordinate2D {
          return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        
        // Returns a copy of the placemarks name
        func getName() -> String {
            let copy = MTPlacemark(nameEditDate: nil)
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
    
    @Model
    final class Run: Identifiable{
        public var id: String = UUID().uuidString
        var isDarkMode: Bool = true
        var postedDate: Date = Date()
        var startTime: Date = Date()
        var endTime: Date = Date()
        var elapsedTime: Int  = 0
        var distanceTraveled: Double  = 0.0
        var routeDistance: Double = 0.0
        var steps: Int = 0
        var startPlacemark: MTPlacemark?
        @Relationship(deleteRule: .noAction) var endPlacemark: MTPlacemark?
        var avgSpeed: Double = 0.0
        var avgPace: Int  = 0
        @Attribute(.externalStorage) var routeImage: Data?
        var notes: String = ""
        @Relationship(deleteRule: .cascade) var paceArray: Array<Pace>? // new field
        
        init(id: String = UUID().uuidString, isDarkMode: Bool, postedDate:Date, startTime: Date, endTime: Date, elapsedTime: Int, distanceTraveled: Double, routeDistance: Double, steps: Int, startPlacemark: MTPlacemark, endPlacemark: MTPlacemark,  avgSpeed: Double, avgPace: Int, routeImage: Data, notes: String = "", paceArray: [Pace]) {
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
            self.paceArray = paceArray
        }
    }
    
    @Model
    final class Pace: Identifiable{
        public var id: String = UUID().uuidString
        var pace: Int = 0               // stored as seconds per meter
        var timeSeconds: Int = 0
        @Relationship(inverse: \Run.paceArray) var runs: [Run]?

        init(pace: Int = 0, timeSeconds: Int = 0 ) {
            self.pace = pace
            self.timeSeconds = timeSeconds
        }
    }
    
}



enum SoloSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [User.self, Run.self, Location.self, MTPlacemark.self, Pace.self]
    }
    
    @Model
    public class User {
        public var id: String = UUID().uuidString
        var fullName: String = "User Name"
        var streak: Int = 0
        var streakLastDoneDate: Date?
        @Attribute(.externalStorage) var profilePicture: Data?

        var longestStreak: Int = 0
        
        init(fullName: String? = "User Name", streak: Int? = 0, streakLastDoneDate: Date? = Date(), profilePicture: Data? = nil, longestStreak: Int? = 0) {
            self.fullName = fullName ?? ""
            self.streak = streak ?? 0
            self.streakLastDoneDate = streakLastDoneDate
            self.profilePicture = profilePicture
            self.longestStreak = longestStreak ?? 0
        }
    }
    
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
        var nameEditDate: Date?
        
        // Cloudkit requires inverse relationships even if you don't use them
        @Relationship(inverse: \Run.startPlacemark) var runsStartingHere: [Run]?
        @Relationship(inverse: \Run.endPlacemark) var runsEndingHere: [Run]?
        
      
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
             timestamp: Date = Date(),
             nameEditDate: Date?
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
            self.nameEditDate = nameEditDate
        }
        
        // Method to get CLLocationCoordinate2D for start placemark
        func getLocation() -> CLLocationCoordinate2D {
          return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        
        // Returns a copy of the placemarks name
        func getName() -> String {
            let copy = MTPlacemark(nameEditDate: nil)
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
    
    @Model
    final class Run: Identifiable{
        public var id: String = UUID().uuidString
        var isDarkMode: Bool = true
        var postedDate: Date = Date()
        var startTime: Date = Date()
        var endTime: Date = Date()
        var elapsedTime: Int  = 0
        var distanceTraveled: Double  = 0.0
        var routeDistance: Double = 0.0
        var steps: Int = 0
        var startPlacemark: MTPlacemark?
        @Relationship(deleteRule: .noAction) var endPlacemark: MTPlacemark?
        var avgSpeed: Double = 0.0
        var avgPace: Int  = 0
        @Attribute(.externalStorage) var routeImage: Data?
        @Attribute(.externalStorage) var breadCrumbImage: Data?
        var notes: String = ""
        @Relationship(deleteRule: .cascade) var paceArray: Array<Pace>? // new field
        
        init(id: String = UUID().uuidString, isDarkMode: Bool, postedDate:Date, startTime: Date, endTime: Date, elapsedTime: Int, distanceTraveled: Double?, routeDistance: Double, steps: Int, startPlacemark: MTPlacemark, endPlacemark: MTPlacemark,  avgSpeed: Double, avgPace: Int, routeImage: Data?, breadCrumbImage: Data?, notes: String = "", paceArray: [Pace]) {
            self.id = id
            self.isDarkMode = isDarkMode
            self.postedDate = postedDate
            self.startTime = startTime
            self.endTime = endTime
            self.elapsedTime = elapsedTime
            self.steps = steps
            self.distanceTraveled = distanceTraveled ?? 0.0
            self.routeDistance = routeDistance
            self.startPlacemark = startPlacemark
            self.endPlacemark = endPlacemark
            self.avgSpeed = avgSpeed
            self.avgPace = avgPace
            self.routeImage = routeImage
            self.breadCrumbImage = breadCrumbImage
            self.notes = notes
            self.paceArray = paceArray
        }
    }
    
    @Model
    final class Pace: Identifiable{
        public var id: String = UUID().uuidString
        var pace: Int = 0               // stored as seconds per meter
        var timeSeconds: Int = 0
        @Relationship(inverse: \Run.paceArray) var runs: [Run]?

        init(pace: Int = 0, timeSeconds: Int = 0 ) {
            self.pace = pace
            self.timeSeconds = timeSeconds
        }
    }
    
}
