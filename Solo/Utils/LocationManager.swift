//
//  LocationManager.swift
//  Solo
//
//  Created by William Kim on 10/15/24.
//

import Foundation
import MapKit
import Combine
import CoreMotion

class LocationManager: NSObject, ObservableObject, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @Published var manager = CLLocationManager()

    @Published var userLocation: CLLocation?
    @Published var isAuthorized = false
    
    @Published var searchText: String = ""
    @Published var fetchedPlaces: [CLPlacemark]?
    
    @Published var routeSteps: [MKRoute.Step] = []
    @Published var stepCoordinates: [CLLocationCoordinate2D] = []
    @Published var remainingDistanceToStep: CLLocationDistance? // distance in meters
    
    @Published var startPlacemark: CLPlacemark?
    @Published var endPlacemark: CLPlacemark?

    
    var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        startLocationServices()
        manager.delegate = self
        
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
    
    
    func updateStartEndPlacemarks(start: CLPlacemark, end: CLPlacemark) {
        self.startPlacemark = start
        self.endPlacemark = end
        
        print("saved start and end placemarks")
    }
    
    func clearData() {
        self.startPlacemark = nil
        self.endPlacemark = nil
        self.fetchedPlaces?.removeAll()
        self.routeSteps.removeAll()
        self.remainingDistanceToStep = nil
    }
    
    
    func startLocationServices() {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            isAuthorized = true
//            manager.allowsBackgroundLocationUpdates = true

        } else {
            isAuthorized = false
            manager.requestWhenInUseAuthorization()
        }
        
    }
    

    
    

    //  Invoked when a user creates a route with directions
    func updateStepCoordinates(steps: [MKRoute.Step]) {
        routeSteps = steps
        
        for step in steps {
            let coordinate = step.polyline.coordinate
            stepCoordinates.append(coordinate)
        }
    }
    
    
    // updates user location and calculates next step with remaining distance
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last

        if !stepCoordinates.isEmpty  {
 
            let nextStepCoordinate = stepCoordinates.first
            let nextStepLocation = CLLocation(latitude: nextStepCoordinate!.latitude, longitude: nextStepCoordinate!.longitude)
            
            remainingDistanceToStep = userLocation!.distance(from: nextStepLocation)
//            print("distance to instruction: \(routeSteps.first?.instructions) is \(remainingDistanceToStep)")
            
            // get next step if within 10 meters of current step
            if remainingDistanceToStep! < 10 {
                let isFinished = moveToNextStep()
                if isFinished {
                    print("Done with run!")
                }
            }
        }
    }
    
    
    func moveToNextStep() -> Bool {
        stepCoordinates.removeFirst()
        routeSteps.removeFirst()
        
        if routeSteps.isEmpty {
            return true
        }
        return false
    }
    
    
//    func findClosestRouteStep() -> Int{
//        if userLocation != nil {
//            for (index, coordinate) in stepCoordinates.enumerated() {
//                let stepLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//                let distance = userLocation!.distance(from: stepLocation)
//                
//                // Check if the user is within a certain threshold (e.g., 20 meters) of the step
//                if distance < 20 {
//                    return index // Return the index of the next step the user is close to
//                }
//            }
//        }
//       return -1 // Return nil if no step is close enough
//    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            manager.requestLocation()
            
        case .notDetermined:
            isAuthorized = false
            manager.requestWhenInUseAuthorization()
        case .denied:
            isAuthorized = false
            print("Access denied")
            // should navigate to new screen to tell user to turn on location services
        default:
            isAuthorized = true
            startLocationServices()
        }
    }
    
    func fetchPlaces(search: String) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = search.lowercased()
                
                let response =  try await MKLocalSearch(request: request).start()
                await MainActor.run(body: {
                    self.fetchedPlaces = response.mapItems.compactMap({item -> CLPlacemark? in
                        return item.placemark
                    })
                })
            } catch {
                
            }
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager did fail: \(error)")
    }
        
    
}
