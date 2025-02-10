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


/**
 Manages user location, routing, and dynamic data as user interacts with run configurations in the run view.
 */
class LocationManager: NSObject, ObservableObject, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @Published var manager = CLLocationManager()

    @Published var userLocation: CLLocation?
    @Published var isAuthorized = false
    
    @Published var searchText: String = ""
    @Published var fetchedPlaces: [MTPlacemark]?
    
    @Published var routeSteps: [MKRoute.Step] = []
    @Published var stepCoordinates: [CLLocationCoordinate2D] = []
    
    @Published var remainingDistanceToStep: CLLocationDistance? // distance in meters
    
    @Published var startPlacemark: MTPlacemark?
    @Published var endPlacemark: MTPlacemark?

    
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
    
    
    func updateStartEndPlacemarks(start: MTPlacemark, end: MTPlacemark) {
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
        self.searchText = ""
    }
    
    
    func clearSearchField() {
        self.searchText = ""
    }
    
    
    func startLocationServices() {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            isAuthorized = true
        } else {
            isAuthorized = false
            manager.requestWhenInUseAuthorization()
        }
        
    }
    
    func beginTracking() {
        manager.startUpdatingLocation()
    }
    
    func terminateTracking() {
        manager.stopUpdatingLocation()
    }
    
    func updateStepCoordinates(steps: [MKRoute.Step]) {
           routeSteps = steps
           
           for step in steps {
               let coordinate = step.polyline.coordinate
               stepCoordinates.append(coordinate)
           }
       }
    


    // Updates the user location which is reflected on the map 
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager did fail: \(error)")
    }
        
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            print("location authorization enabled")
            manager.requestLocation()
            
        case .notDetermined:
            isAuthorized = false
            print("location authorization not determined")
            manager.requestWhenInUseAuthorization()
        case .denied:
            isAuthorized = false
            print("location authorization denied")
        default:
            isAuthorized = true
            startLocationServices()
        }
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
                    })
                })
            } catch {
                
            }
        }
    }

    
}
