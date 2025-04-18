//
//  ActivityManager.swift
//  Solo
//
//  Created by William Kim on 10/18/24.
//

import Foundation
import CoreMotion
import Combine
import ActivityKit
import MapKit
import SwiftUI
import os


/**
  The emitted data that Live Widgets use to display to the user about an active run session
 */
struct SoloLiveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var steps: Int
    }

    // Fixed non-changing properties about your activity go here!
    var startTime: Date
    var endTime: Date

}

struct BreadcrumbData {
    /// The locations in the breadcrumb path.
    var locations: [CLLocation]
 
    /// The backing storage for the path bounds.
    var bounds: MKMapRect
        
    init(locations: [CLLocation] = [CLLocation](), pathBounds: MKMapRect = MKMapRect.world) {
        self.locations = locations
        self.bounds = pathBounds
    }
}


/**
  Manages the monitoring of time, Core Motion  data, and execution of any Live Activities for an active run session.
 */
class RunManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var locationManager = CLLocationManager()
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    // State related to time and pedometer data
    @Published var isMotionAuthorized: Bool = false
    @Published var steps: Int = 0
    @Published var distanceTraveled: Double = 0.0 // estimated distance in meters
    @Published var averageSpeed: Double = 0     // speed in miles per hour
    @Published var averagePace: Int = 0         // minutes per mile
    
    @Published var runStartTime: Date = Date()
    @Published var runEndTime: Date = Date()
    @Published var maxEndTime: Date?
    
    @Published var secondsElapsed: Int = 0
    @Published var formattedDuration: String = ""
    @Published var activePaceArray: Array<Pace> = []

    // State related to location and searching for places
    @Published var userLocation: CLLocation?
    @Published var isAuthorized = false
    
    @Published var searchText: String = ""
    var cancellable: AnyCancellable?

    // Route details
    @Published var isFreeRunning: Bool = false
    @Published var fetchedPlaces: [MTPlacemark]?
    @Published var startPlacemark: MTPlacemark?
    @Published var endPlacemark: MTPlacemark?
    @Published var routeDistance: Double = 0.0
    @Published var routeSteps: [MKRoute.Step] = []
    

    // Breadcrumb data
    @Published var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @AppStorage("breadCrumbAccuracy") var breadCrumbAccuracy: Int = BreadCrumbAccuracyOption.tenMeters.rawValue
    @Published var didOptForBreadCrumbTracking: Bool = true
    @Published var bestLocationAccuracy: Bool = true

    private let protectedBreadcrumbData = OSAllocatedUnfairLock(initialState: BreadcrumbData())
    
    var pathBounds: MKMapRect {
        return protectedBreadcrumbData.withLock { breadcrumbData in
            return breadcrumbData.bounds
        }
    }
    
    var locations: [CLLocation] {
        return protectedBreadcrumbData.withLock { breadcrumbData in
            return breadcrumbData.locations
        }
    }

    
    // Live activity
    private var activity: Activity<SoloLiveWidgetAttributes>?
    @MainActor @Published private(set) var activityID: String? // unique identifier for started activity

    
    override init()  {
        super.init()    
       
        let today = Date()
        activityManager.queryActivityStarting(from: today, to: today, to: OperationQueue.main, withHandler: { (activities: [CMMotionActivity]?, error: Error?) -> () in
           if error != nil {
               let errorCode = (error! as NSError).code
               if errorCode == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                   print("Activity manager not authorized")
                   self.setMotionAuthorization(value: false)
               }
           } else {
               print("Activity manager authorized")
               self.setMotionAuthorization(value: true)
           }
        })
        
        startLocationServices()
        locationManager.delegate = self
        
        cancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: {value in
                if (value != "") {
                    self.fetchPlaces(search: value)
                } else {
                    self.fetchedPlaces = nil
                }
            })
    }
    
    private var isPedometerAvailable: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() &&
        CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
     }
    
 
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager did fail: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did update location")
        self.userLocation = locations.last

        fetchPedometerData()
        updateLiveActivity()
        
        if self.didOptForBreadCrumbTracking {
            for location in locations {
                addNewBreadCrumb(location)
            }
        }
        else {
            print("did not opt for breadcrumb tracking")
        }
    }

    
    func addNewBreadCrumb(_ newLocation: CLLocation) {
        
        // The new location has to be recent and above the minimum separation distance
      
        self.protectedBreadcrumbData.withLock { breadcrumbData in
     
            guard isLocationUsable(newLocation, breadcrumbData: breadcrumbData) else {
                return
            }
            
            print("location is usable")
            
            var previousLocation = breadcrumbData.locations.last
            
            if breadcrumbData.locations.isEmpty {
                // For the first location in the array, fake a previous location so that calculating the bounds
                // change has something to compare against.
                previousLocation = newLocation
            }
            
            breadcrumbData.locations.append(newLocation)
            
            // Compute the `MKMapRect` bounding the most recent location, and the new location.
            let pointSize = MKMapSize(width: 0, height: 0)
            let newPointRect = MKMapRect(origin: MKMapPoint(newLocation.coordinate), size: pointSize)
            let prevPointRect = MKMapRect(origin: MKMapPoint(previousLocation!.coordinate), size: pointSize)
            let pointRect = newPointRect.union(prevPointRect)
            
            if !breadcrumbData.bounds.contains(pointRect) {
                /**
                 Extends `pathBounds` to include the contents of `rect`, plus some additional padding.
                 The padding allows for the bounding rectangle to only grow sporadically, rather than after adding nearly
                 every additional point to the crumb path.
                 */
                var grownBounds = breadcrumbData.bounds.union(pointRect)
                
                /**
                 The number of map points per unit of distance varies based on latitude. To grow the bounds exactly by 1 kilometer,
                 each edge of the bounds needs to change by a different amount of map points. The padding amount doesn't
                 need to be exactly 0.3 kilometer, so instead, determine the number of map points at the new rectangle's latitude
                 and use this value for the padding amount for all edges, even though it doesn't represent exactly 0.1 kilometer.
                */
                let paddingAmountInMapPoints = 200 * MKMapPointsPerMeterAtLatitude(pointRect.origin.coordinate.latitude)
                
                // Grow by an extra kilometer in the direction of the overrun.
                if pointRect.minY < breadcrumbData.bounds.minY {
                    grownBounds.origin.y -= paddingAmountInMapPoints
                    grownBounds.size.height += paddingAmountInMapPoints
                }
                
                if pointRect.maxY > breadcrumbData.bounds.maxY {
                    grownBounds.size.height += paddingAmountInMapPoints
                }
                
                if pointRect.minX < breadcrumbData.bounds.minX {
                    grownBounds.origin.x -= paddingAmountInMapPoints
                    grownBounds.size.width += paddingAmountInMapPoints
                }
                
                if pointRect.maxX > breadcrumbData.bounds.maxX {
                    grownBounds.size.width += paddingAmountInMapPoints
                }
                
                // Ensure the updated `pathBounds` is never larger than the world size.
                breadcrumbData.bounds = grownBounds.intersection(.world)
            }
            else {
                print("skipping bounds update")
            }
        }
    }
    

    private func isLocationUsable(_ location: CLLocation, breadcrumbData: BreadcrumbData) -> Bool {
        let now = Date()
        let locationAge = now.timeIntervalSince(location.timestamp)
        guard locationAge < 60 else {
            print("not usable location")
            return  false
        }
                
        if breadcrumbData.locations.isEmpty { return true }
    
        let minimumDistanceBetweenLocationsInMeters = Double(breadCrumbAccuracy)
        let previousLocation = breadcrumbData.locations.last!
        let metersApart = location.distance(from: previousLocation)
        
        return metersApart > minimumDistanceBetweenLocationsInMeters
    
    }
    
    func setMotionAuthorization(value: Bool) {
        DispatchQueue.main.async {
            self.isMotionAuthorized = value
        }
    }
    

    func clearSearchField() {
        self.searchText = ""
    }
    
    func clearData() {
        DispatchQueue.main.async {
            self.startPlacemark = nil
            self.endPlacemark = nil
            
            self.distanceTraveled = 0
            self.steps = 0
            self.averagePace = 0
            self.activePaceArray.removeAll()

            self.fetchedPlaces?.removeAll()
            self.routeSteps.removeAll()
            self.searchText = ""
            
            self.runStartTime = Date()
            self.runEndTime = Date()
            self.isFreeRunning = false
            self.didOptForBreadCrumbTracking = false
            
            self.resetUserLocation() // set user location to most recent locations
            
            self.protectedBreadcrumbData.withLock { breadcrumbData in
                breadcrumbData.locations.removeAll()
                breadcrumbData.bounds = MKMapRect.world
            }
             
        }
    }
    
    func resetUserLocation() {
        if let latestLocation = self.locationManager.location {
            self.userLocation = latestLocation
        }
    }
        
    func updateRouteSteps(steps: [MKRoute.Step]) {
         routeSteps = steps
     }
    
    // This listens for changes in pedometer authorizations
    func checkPedometerAuthorization() {
        switch CMPedometer.authorizationStatus() {
            
        case .notDetermined:
            print("core motion authorizations not determined")
            setMotionAuthorization(value: false)
        case .denied:
            print("core motion authorization denied")
            setMotionAuthorization(value: false)
        case .authorized:
            print("core motion authorized")
            setMotionAuthorization(value: true)
        default:
            print("core motion authorized by default")
            setMotionAuthorization(value: true)
        }
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            print("location authorization enabled")
            locationManager.requestLocation()
            
        case .notDetermined:
            isAuthorized = false
            print("location authorization not determined")
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            isAuthorized = false
            print("location authorization denied")
        default:
            isAuthorized = true
            startLocationServices()
        }
    }
    
    
    func startLocationServices() {
        if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
            isAuthorized = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.desiredAccuracy = self.bestLocationAccuracy ? kCLLocationAccuracyBest : kCLLocationAccuracyNearestTenMeters
        } else {
            isAuthorized = false
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    func storeRouteDetails(start: MTPlacemark, end: MTPlacemark? = nil, distance: Double? = nil) {
        self.startPlacemark = start
        print("stored start placemark: \(start.name)")
        
        if end != nil {
            self.endPlacemark = end!
        }
        if distance != nil {
            self.routeDistance = distance!
        }
    }

    
    // Fetches pedometer data at the current time when app receives location updates in background
    func fetchPedometerData() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        self.pedometer.queryPedometerData(from: Date(), to: Date()) { data, error in
            if let error = error {
                print("pedometer  error: \(error)")
                return
            }
            
            if let data = data {
                DispatchQueue.main.async {
                    if data.numberOfSteps.intValue > 0 {
                        self.steps = data.numberOfSteps.intValue
                        self.distanceTraveled = data.distance?.doubleValue ?? 0
                    }
                    
                    if let paceValue = data.averageActivePace {
                        let secondsElapsed = Date().timeIntervalSince(self.runStartTime)
                        let newPace = Pace(pace: paceValue.intValue, timeSeconds: Int(secondsElapsed))
                        self.activePaceArray.append(newPace)
                    }
                }
            }
        }
    }
    
    
    func startMotionAndActivityTracking() async {
        
        // We should always start the run regardless of live activity permissions
        await startLiveActivity { _ in

            if self.isPedometerAvailable {
                
                // The pedometer will track distance and steps
                self.pedometer.startUpdates(from: self.runStartTime) { (data, error) in
                    if let error = error {
                        print("pedometer start updates  error: \(error)")
                        return
                    }
                    
                    if let data = data {
                        DispatchQueue.main.async {
                            self.steps = data.numberOfSteps.intValue
                            self.distanceTraveled = data.distance?.doubleValue ?? 0
                            
                            if let paceValue = data.averageActivePace {
                                let secondsElapsed = Date().timeIntervalSince(self.runStartTime)
                                let newPace = Pace(pace: paceValue.intValue, timeSeconds: Int(secondsElapsed))
                                self.activePaceArray.append(newPace)
                            }
                        }
                    }
                }
            }
        }
    }
    
        
    // Prepare to launch the run session only if the user had previously authorized the use of the pedometer
    func beginRunSession() async {
        
        DispatchQueue.main.sync {
            self.runStartTime = Date.now
            self.maxEndTime = self.runStartTime.addingTimeInterval(24 * 60 * 60) // 24 hour max
        }
        
        if self.didOptForBreadCrumbTracking {
            self.protectedBreadcrumbData.withLock { breadcrumbData in
                
                breadcrumbData.locations.append(self.userLocation!)
            
                let coordinate =  self.userLocation!.coordinate
                let origin = MKMapPoint(coordinate)
                
                // The default `pathBounds` size is 0.2 square kilometer that centers on `coordinate`.
                let oneKilometerInMapPoints = 200 * MKMapPointsPerMeterAtLatitude(coordinate.latitude)
                let oneSquareKilometer = MKMapSize(width: oneKilometerInMapPoints, height: oneKilometerInMapPoints)
                breadcrumbData.bounds = MKMapRect(origin: origin, size: oneSquareKilometer)
                print("is empty. created new bounds: \(breadcrumbData.bounds)")
                
                // Clamp the rectangle to be within the world.
                breadcrumbData.bounds = breadcrumbData.bounds.intersection(.world)
            }
        }
        
        if CMPedometer.authorizationStatus() == .authorized {
            await startMotionAndActivityTracking()
            locationManager.startUpdatingLocation()

        }
        else {
            // Maybe show an error to the user that core motion needs to be enabled
            setMotionAuthorization(value: false)
        }
        
    }

    
    // Stop the timer and capture the user's final statistics
    func endRunSession(completion: @escaping (Bool) -> Void) async {
        
        DispatchQueue.main.sync {
            self.runEndTime = Date.now
            self.secondsElapsed = Int(self.runEndTime.timeIntervalSince(self.runStartTime))
        }
        
        if self.isFreeRunning {
            if let userLocation = self.userLocation {
                self.lookUpLocation(location: userLocation) { endPlacemark in
                    self.endPlacemark = endPlacemark
                    //print("Saved free run end placemark: \(self.endPlacemark?.name)")
                    if endPlacemark == nil {
                        completion(false)
                    }
                }
            }

        }
                
        await endLiveActivity()
        pedometer.stopUpdates()
        locationManager.stopUpdatingLocation()

        if isPedometerAvailable {
            pedometer.queryPedometerData(from: runStartTime, to: runEndTime) { (data, error) in
                DispatchQueue.main.async {
                    let distanceInMiles = Double(self.distanceTraveled) / 1609.34
                    // Averaege speed in miles per hour
                    self.averageSpeed = distanceInMiles / (Double(self.secondsElapsed) / 3600)
                    
                    // Average pace in minutes/mile
                    if self.averageSpeed > 0 {
                        self.averagePace = Int((1.0 / self.averageSpeed) * 60)
                    } else {
                        self.averagePace = 0
                    }
                }
            }
        }
        
        completion(true)
    }
    
    
    func fetchPlaces(search: String) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                let region = MKCoordinateRegion(
                    center: userLocation!.coordinate,
                    span: .init(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
                
                request.region = region
                request.naturalLanguageQuery = search.lowercased()
                
                let response =  try await MKLocalSearch(request: request).start()
                await MainActor.run(body: {
                    self.fetchedPlaces = response.mapItems.compactMap({item -> MTPlacemark? in
                        let placemark = item.placemark
                        return MTPlacemark(
                            name: placemark.name ?? "",
                            thoroughfare: placemark.thoroughfare ?? "",
                            subThoroughfare: placemark.subThoroughfare ?? "",
                            locality: placemark.locality ?? "",
                            subLocality: placemark.subLocality ?? "",
                            administrativeArea: placemark.administrativeArea ?? "",
                            subAdministrativeArea: placemark.subAdministrativeArea ?? "",
                            postalCode: placemark.postalCode ?? "",
                            country: placemark.country ?? "",
                            isoCountryCode: placemark.isoCountryCode ?? "",
                            longitude: placemark.location!.coordinate.longitude,
                            latitude: placemark.location!.coordinate.latitude,
                            isCustomLocation: false,
                            timestamp: Date(),
                            nameEditDate: nil
                        )
                    }).filter{$0.isoCountryCode == "US"}
                })
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func lookUpLocation(location: CLLocation, completionHandler: @escaping (MTPlacemark?) -> Void ) {
        let geocoder = CLGeocoder()
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(
        CLLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude),
            completionHandler: { (placemarks, error) in
                if error == nil {
                    
                    if let firstLocation = placemarks?[0] {
                        let placemark = MTPlacemark(
                            name: firstLocation.name ?? "",
                            thoroughfare: firstLocation.thoroughfare ?? "",
                            subThoroughfare: firstLocation.subThoroughfare ?? "",
                            locality: firstLocation.locality ?? "",
                            subLocality: firstLocation.subLocality ?? "",
                            administrativeArea: firstLocation.administrativeArea ?? "",
                            subAdministrativeArea: firstLocation.subAdministrativeArea ?? "",
                            postalCode: firstLocation.postalCode ?? "",
                            country: firstLocation.country ?? "",
                            isoCountryCode: firstLocation.isoCountryCode ?? "",
                            longitude: firstLocation.location!.coordinate.longitude,
                            latitude: firstLocation.location!.coordinate.latitude,
                            isCustomLocation: false,
                            timestamp: Date(),
                            nameEditDate: nil
                        )
                        completionHandler(placemark)
                    }
                }
                else {
                    completionHandler(nil)
                }
            }
        )
    }
    
    
    func startLiveActivity(completion: @escaping (Bool) -> Void) async {
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = SoloLiveWidgetAttributes(startTime: runStartTime, endTime: maxEndTime!)
            let initialState = SoloLiveWidgetAttributes.ContentState(steps: 0)
            
            activity = try? Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(28800))
            )
            
            guard let activity = activity else {
                return completion(false)
            }
            
            await MainActor.run { activityID = activity.id }
            print("ACTIVITY IDENTIFIER:\n\(activity.id)")
            return completion(true)
        }
    }
    
    
    func updateLiveActivity()  {
        Task {
            guard let activityID = await activityID,
                  let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }
            let newRandomContentState = SoloLiveWidgetAttributes.ContentState(steps: self.steps)
            await runningActivity.update(using: newRandomContentState)
        }
    }
    
    
    func endLiveActivity() async {
        guard let activityID = await activityID,
              let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
            return
        }
        let initialContentState = SoloLiveWidgetAttributes.ContentState(steps: 0)
        
        await runningActivity.end(
            ActivityContent(state: initialContentState, staleDate: Date.distantFuture),
            dismissalPolicy: .immediate
        )
        
        await MainActor.run {
            self.activityID = nil
        }
    }
}
    

