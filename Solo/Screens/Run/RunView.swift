//
//  RunView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//
// https://www.rudrank.com/exploring-swiftui-detecting-and-controlling-bottom-sheet-position/




import Foundation
import SwiftUI
import MapKit
import SwiftData
import CoreHaptics
import AlertToast

enum RunStatus: String {
    case planningRoute = "planning route", startedRun = "started run", endedRun = "ended run"
}

enum SheetPosition: CGFloat, CaseIterable {
    case peek = 0.25
    case detailed = 0.50
    case full = 0.95

    var detent: PresentationDetent {
        .fraction(rawValue)
    }
    static let detents = Set(SheetPosition.allCases.map { $0.detent })
}

enum GeocodingError: Error {
    case timeout
    case failedToRetrieve
    case noMatchingAddress
}


enum BreadCrumbAccuracyOption: Int, CaseIterable {
    case tenMeters = 10
    case fiftyMeters = 50
    case hundredMeters = 100
    case fiveHundredMeters = 500
}

/**
 Renders an interactive map using MapKit that enables pan, zoom, and rotate gestures. Users can find specific locations
 using a search bar with matching results appearing as Markers on the map. Custom pins can also be added by dragging a
 pin around the region. A sheet will appear for displaying a run session with realtime data broadcasted to the user and
 a LiveActivity Widget if enabled.  When a user is done, the view will process a MapSnapshot of the route along with the recorded run data.
 */
struct RunView: View {
    
    // Environment objects to handle music, location, and activity monitoring
    @EnvironmentObject var runManager: RunManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    
    @State var startedRun: Bool = false
    @State var runStatus: RunStatus = .planningRoute
    @Binding var showRunView: Bool
    
    // Loading States
    @State var isStartRunLoading: Bool = false
    @State var isFinishRunLoading: Bool = false
    @State var isLoadingAssociatedRuns: Bool = false
    
    // Bottom sheet visibility states
    @State var searchPlaceSheetVisible: Bool = true
    @State var routeSheetVisible: Bool = false
    @State var editCustomPinNameSheetVisible: Bool = false
    @State var viewPinAssociatedRunsSheetVisible: Bool = false
    
    @State var runSheetVisible: Bool = false
    @State var stepsSheetVisible: Bool = false
    @State var customPinSheetVisible: Bool = false
    
    // Sheet position targets. The first two are designed to make their sheet positions dynamically change according to user specific requirements
    @State private var searchPlaceSheetSelectedDetent: PresentationDetent = SheetPosition.peek.detent
    @State private var routeSheetSelectedDetent: PresentationDetent = SheetPosition.peek.detent
    
    @State private var searchPlaceSheetDetents: Set<PresentationDetent> = SheetPosition.detents
    @State private var routeSheetDetents: Set<PresentationDetent> =   SheetPosition.detents
    @State private var editCustomPinNameSheetDetents: Set<PresentationDetent> = [.medium, .large]
    @State private var viewPinAssociatedRunsSheetDetents: Set<PresentationDetent> = [.medium, .large]
    @State private var runSheetDetents: Set<PresentationDetent> =  [.fraction(0.25), .medium, .large]
    @State private var stepsSheetDetents: Set<PresentationDetent> = [.medium, .large]
    
    // Search text field and focus state
    @FocusState private var isTextFieldFocused: Bool
    @State var addressInput: String = ""
    
    // Custom pin interaction states
    @State var associatedRuns: [Run] = []
    @State var newCustomPinName: String = ""
    
    // Map variables to handle interactions and camera
    @State var interactionModes: MapInteractionModes = [.all] // gestures for map view
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // Track which placemark the user selected on the map
    @State var selectedPlaceMark: MTPlacemark? // the destination that the user selected
    
    // Custom pin variables to track custom pin state
    @Query(filter: #Predicate<MTPlacemark> { place in
        return place.isCustomLocation == true
    },sort: \MTPlacemark.name) var allCustomPinLocations: [MTPlacemark]
    
    
    // Query the most recent 16 runs. Used to check if free tier users used up their run limit per month
    static var recentRunsDescriptor: FetchDescriptor<Run> {
        var descriptor = FetchDescriptor<Run>(sortBy: [SortDescriptor(\.postedDate, order: .reverse)])
        descriptor.fetchLimit = RUN_LIMIT
        return descriptor
    }
    

    @Query(recentRunsDescriptor) var recentRuns: [Run]
    @State var runsThisMonth: [Run] = []
    @State var allRunsCount: Int = 0
    
    @Query var userData: [User]
    var user: User? {userData.first}
    
    
    @State var isPinActive: Bool = false
    @State var pinCoordinates: CLLocationCoordinate2D?
    @State var usePin: Bool = false
    

    // Variables that handle the type of annotations displayed on the map
    @State private var showRoute = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDestination: MTPlacemark?
    @State private var transportType = MKDirectionsTransportType.walking
    @State private var routeDistance: Double = 0.0
    
    // The elapsed time in seconds
    @State private var travelInterval: TimeInterval?
    var travelTimeString: String? {
        guard let travelInterval else { return nil }
        let formatter  = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        
        return formatter.string(from: travelInterval)
    }
    
    // Array that holds all the coordinates of each step along a given route
    @State private var stepCoordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D()]
    
    // Dialog when user acccesses a locked pro feature
    @State private var showProAccessPinsDialog: Bool = false
    @State private var showProAccessRunsDialog: Bool = false

    // Tracks if timer is paused or playing
    @State private var isPaused: Bool = false
    
    // Toggle visibility of breadcrumb path
    @State private var showBreadCrumbPath: Bool = false
    
    // Confirmation dialog to end the run
    @State private var isShowingEndRunDialog: Bool = false
    
    // Confirmation dialog to delete a custom pin
    @State private var isShowingDeleteCustomPinDialog: Bool = false
    
    // Subsequent route fetches are disabled when viewing current route details
    @State private var disabledFetch: Bool = false
    
    // If user has finished saving a run, navigate to run summary view
    @State private var canShowSummary: Bool = false
        
    @State private var isCustomPinNewNameSaved: Bool = false
        
    @AppStorage("displayBreadCrumbPath") var displayBreadCrumbPath: Bool = true
    @AppStorage("breadCrumbAccuracy") var breadCrumbAccuracy: Int = BreadCrumbAccuracyOption.tenMeters.rawValue

    
    func saveNewCustomPinName() {
        isCustomPinNewNameSaved = false
        if !newCustomPinName.isEmpty {
            routeDestination!.name = newCustomPinName
            routeDestination?.nameEditDate = Date.now
            isCustomPinNewNameSaved = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                newCustomPinName = ""
                isCustomPinNewNameSaved = false
            }
        }
    }
    
    // Code source: https://www.youtube.com/watch?v=yVMvOXGMd_Q&t=698s
    func fetchRoute() async  {
        print("fetching route")
        
        if disabledFetch || runStatus == .startedRun {
            print("route fetch disabled")
            return
        }
        
        runManager.resetUserLocation()
        
        if let userLocation = runManager.userLocation, let selectedPlaceMark {
            let request = MKDirections.Request()
            let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
            let routeSource = MKMapItem(placemark: sourcePlacemark)
            
            let destinationPlacemark = MKPlacemark(coordinate: selectedPlaceMark.getLocation())
            
            request.source = routeSource
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = transportType
            
            let directions = MKDirections(request: request)
            let result = try? await directions.calculate()
            
            route = result?.routes.first
            routeDestination = selectedPlaceMark
            
            if let route {
                runManager.updateRouteSteps(steps: route.steps)
                travelInterval = route.expectedTravelTime
                
                let destinationLocation = CLLocation(latitude: routeDestination!.latitude, longitude: routeDestination!.longitude)
                routeDistance =  Double(route.distance) / 1609.34 //runManage.userLocation!.distance(from: destinationLocation)

                print("routeDisplaying set to true")
                routeDisplaying = true
                routeSheetVisible = true
            }
        }
    }
    
    
    func fetchCustomPinLocation(completionHandler: @escaping (Result<CLPlacemark, GeocodingError>) -> Void){
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: pinCoordinates!.latitude, longitude: pinCoordinates!.longitude)
        
        var isCompleted = false // Track if request completes before timeout
            
        // Define a timeout work item
        let timeoutWorkItem = DispatchWorkItem {
            geocoder.cancelGeocode()
            print("Geocoding request timed out")
            completionHandler(.failure(.timeout))
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0, execute: timeoutWorkItem)
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print("Failed to retrieve address")
                timeoutWorkItem.cancel()
                completionHandler(.failure(.failedToRetrieve))
                return
            }
            if let placemarks = placemarks, let placemark = placemarks.first {
                print("Retrieved address")
                timeoutWorkItem.cancel()
                completionHandler(.success(placemark))
                return
            }
            else{
                print("No Matching Address Found")
                timeoutWorkItem.cancel()
                completionHandler(.failure(.noMatchingAddress))
                return
            }
        })
    }

    
    func fetchAssociatedRunsForPin(pin: MTPlacemark) async {
        isLoadingAssociatedRuns = true
        let id = pin.id
        let fetchDescriptor = FetchDescriptor<Run>(
            predicate: #Predicate<Run> { $0.endPlacemark?.id == id },
            sortBy:[SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            associatedRuns = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("could not fetch runs with custom pin")
            associatedRuns = []
        }
        
        isLoadingAssociatedRuns = false
    }

    
    // Removes a route when user dismisses the details sheet
    func removeRoute() {
        routeDisplaying = false
        showRoute = false
        route = nil
        selectedPlaceMark = nil
        routeDestination = nil
        disabledFetch = false
    }

        
    // Creates at most two map snapshot images of the user's chosen route and any breadcrumb paths if they opted in
    func captureRouteSnapshot(completion: @escaping (UIImage?) -> Void) {
        guard route != nil else {
            completion(nil)
            return
        }
        print("setting up map snapshot configs")

        guard let startPlacemark = runManager.startPlacemark else {return}
        guard let endPlacemark = runManager.endPlacemark else {return}

        let snapshotOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(route!.polyline.boundingMapRect)
        
        let paddingPercentage: CLLocationDegrees = 0.30 // Adjust percentage for padding
        let paddedRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * (1 + paddingPercentage),
                longitudeDelta: region.span.longitudeDelta * (1 + paddingPercentage)
            )
        )

        snapshotOptions.size =  CGSize(width: 600, height: 600)
        snapshotOptions.scale = UIScreen.main.scale
        snapshotOptions.region = paddedRegion
        snapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: isDarkMode ? .dark : .light)

        let snapshotter = MKMapSnapshotter(options: snapshotOptions)

        // Start request to create the snapshot image
        snapshotter.start { snapshot, error in

            if let error = error {
                print("Error capturing snapshot: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Draw initial map
            let image = snapshot!.image
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.draw(at: .zero)

            let context = UIGraphicsGetCurrentContext()!
            context.beginPath()
            
            // Convert route's polyline to the snapshot coordinates
            for i in 0..<route!.polyline.pointCount {
                let point = route!.polyline.points()[i]
                let coordinate = point.coordinate
                let pointInSnapshot = snapshot!.point(for: coordinate)

                if i == 0 {
                    context.move(to: pointInSnapshot)
                } else {
                    context.addLine(to: pointInSnapshot)
                }
            }

            // draw the route polyline on the map
            context.setLineWidth(8)
            context.setLineCap(.round)
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.strokePath()
            print("added mk route polyline")

            // Set up the start placemark annotation image
            let startPoint = snapshot!.point(for: startPlacemark.getLocation())
            let startAnnotationTintColor = UIColor.systemBlue
            let startAnnotationImage = UIImage(systemName: "location.circle.fill")!.resize(32,32).withTintColor(startAnnotationTintColor).withRenderingMode(.alwaysOriginal)
            
            // Draw a circle behind the start annotation
            let startBackgroundRect = CGRect(origin: CGPoint(x: startPoint.x + 2.5, y: startPoint.y + 2), size: CGSize(width: 24, height: 24))
            let startBackgroundPath = UIBezierPath(ovalIn: startBackgroundRect)
            UIColor.white.setFill()
            startBackgroundPath.fill()
            
            // Draw the start placemark image
            startAnnotationImage.draw(at: CGPoint(x: startPoint.x, y: startPoint.y))

            // Set up the end placemark annotation image
            let endPoint = snapshot!.point(for: endPlacemark.getLocation())
            let endAnnotationTintColor = endPlacemark.isCustomLocation ? UIColor.systemYellow : UIColor.systemRed
            let endAnnotationImage = UIImage(systemName: "mappin.circle.fill")!.resize(32,32).withTintColor(endAnnotationTintColor).withRenderingMode(.alwaysOriginal)

            // Draw a circle behind the end annotation
            let endBackgroundRect = CGRect(origin: CGPoint(x: endPoint.x + 2.5 , y: endPoint.y + 2), size: CGSize(width: 24, height: 24))
            let endBackgroundPath = UIBezierPath(ovalIn: endBackgroundRect)
            UIColor.white.setFill()
            endBackgroundPath.fill()
            
            // Draw the end placemark image
            endAnnotationImage.draw(at: CGPoint(x: endPoint.x, y: endPoint.y))

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            print("returning final image")
            completion(finalImage)
        }
    }
    
    

    func captureBreadCrumbSnapshot(completion: @escaping (UIImage?) -> Void) {
        
        guard runManager.locations.count >= 2 else {
            print("no breadcrumb path")
            completion(nil)
            return
        }
        guard runManager.startPlacemark != nil else {
            print("no start")
            completion(nil)
            return
        }
        guard runManager.endPlacemark != nil else {
            print("no end")
            completion(nil)
            return
        }

        print("setting up breadcrumb snapshot configs")

        let snapshotOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(runManager.pathBounds)
        print("path bounds region: \(region)")
        
        let paddingPercentage: CLLocationDegrees = 0.05 // Adjust percentage for padding
        let paddedRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * (1 + paddingPercentage),
                longitudeDelta: region.span.longitudeDelta * (1 + paddingPercentage)
            )
        )

        snapshotOptions.size =  CGSize(width: 600, height: 600)
        snapshotOptions.scale = UIScreen.main.scale
        snapshotOptions.region = paddedRegion
        snapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: isDarkMode ? .dark : .light)

        let snapshotter = MKMapSnapshotter(options: snapshotOptions)

        // Start request to create the snapshot image
        snapshotter.start { snapshot, error in

            if let error = error {
                print("Error capturing snapshot: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Draw initial map
            let image = snapshot!.image
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.draw(at: .zero)

            let context = UIGraphicsGetCurrentContext()!
            context.beginPath()
            
            // Convert route's polyline to the snapshot coordinates
            let points = runManager.locations.map { MKMapPoint($0.coordinate) }

            for i in 0..<runManager.locations.count{
                let point = points[i]
                let coordinate = point.coordinate
                let pointInSnapshot = snapshot!.point(for: coordinate)

                if i == 0 {
                    context.move(to: pointInSnapshot)
                } else {
                    context.addLine(to: pointInSnapshot)
                }
            }

            // draw the route polyline on the map
            context.setLineWidth(8)
            context.setLineCap(.round)
            context.setStrokeColor(UIColor(BLUE).cgColor)
            context.strokePath()
            print("added breadcrumb polyline")
            
            
            if route == nil {
            
                // Set up the start placemark annotation image
                let startPoint = snapshot!.point(for: runManager.startPlacemark!.getLocation())
                let startAnnotationTintColor = UIColor.systemBlue
                let startAnnotationImage = UIImage(systemName: "location.circle.fill")!.resize(32,32).withTintColor(startAnnotationTintColor).withRenderingMode(.alwaysOriginal)
                
                // Draw a circle behind the start annotation
                let startBackgroundRect = CGRect(origin: CGPoint(x: startPoint.x + 2.5, y: startPoint.y + 2), size: CGSize(width: 24, height: 24))
                let startBackgroundPath = UIBezierPath(ovalIn: startBackgroundRect)
                UIColor.white.setFill()
                startBackgroundPath.fill()
                
                // Draw the start placemark image
                startAnnotationImage.draw(at: CGPoint(x: startPoint.x, y: startPoint.y))
                
                // Set up the end placemark annotation image
                let endPoint = snapshot!.point(for: runManager.endPlacemark!.getLocation())
                let endAnnotationTintColor = UIColor.systemRed
                let endAnnotationImage = UIImage(systemName: "mappin.circle.fill")!.resize(32,32).withTintColor(endAnnotationTintColor).withRenderingMode(.alwaysOriginal)
                
                // Draw a circle behind the end annotation
                let endBackgroundRect = CGRect(origin: CGPoint(x: endPoint.x + 2.5 , y: endPoint.y + 2), size: CGSize(width: 24, height: 24))
                let endBackgroundPath = UIBezierPath(ovalIn: endBackgroundRect)
                UIColor.white.setFill()
                endBackgroundPath.fill()
                
                // Draw the end placemark image
                endAnnotationImage.draw(at: CGPoint(x: endPoint.x, y: endPoint.y))
            }
            
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            print("returning final image")
            completion(finalImage)
        }
    }
    
 
    // When deleting a custom location, delete all runs that reference the location
    func deleteCustomPin() {
        
        if let routeDestination, routeDestination.isCustomLocation {
            let routeId = routeDestination.id

            let fetchDescriptor = FetchDescriptor<Run>(predicate: #Predicate<Run> {
                $0.endPlacemark?.id == routeId
            })
            
           try? modelContext.transaction {
                do {
                    let runs = try modelContext.fetch(fetchDescriptor)
                    for run in runs {
                        modelContext.delete(run)
                    }
                } catch {
                    print("could not fetch runs with custom pin")
                }
                
                modelContext.delete(routeDestination)
                
                // reset the route state
                routeSheetVisible = false
                searchPlaceSheetVisible = true
                removeRoute()
            }
        }
    }
    
    func addCustomLocation() {
        fetchCustomPinLocation() { result in
            switch result {
            case .success(let customPlacemark):
                let placemark = MTPlacemark(
                    name: customPlacemark.name ?? "",
                    thoroughfare: customPlacemark.thoroughfare ?? "",
                    subThoroughfare: customPlacemark.subThoroughfare ?? "",
                    locality: customPlacemark.locality ?? "",
                    subLocality: customPlacemark.subLocality ?? "",
                    administrativeArea: customPlacemark.administrativeArea ?? "",
                    subAdministrativeArea: customPlacemark.subAdministrativeArea ?? "",
                    postalCode: customPlacemark.postalCode ?? "",
                    country: customPlacemark.country ?? "",
                    isoCountryCode: customPlacemark.isoCountryCode ?? "",
                    longitude: customPlacemark.location!.coordinate.longitude,
                    latitude: customPlacemark.location!.coordinate.latitude,
                    isCustomLocation: true,
                    timestamp: Date(),
                    nameEditDate: nil
                )
                
                modelContext.insert(placemark)
                do {
                    try modelContext.save()
                    print("saved custom location")
                } catch {
                    print(error)
                }
                usePin = false
                
            case .failure(.timeout):
                print("request timed out")
                
            case .failure(.failedToRetrieve):
                print("Failed to retrieve address.")
                
            case .failure(.noMatchingAddress):
                print("No matching address found.")
            }
 
        }
    }
    
    func sfSymbolForDirection(instruction: String) -> String {
        let lowercased = instruction.lowercased()
        
        switch lowercased {
        case _ where lowercased.contains("left"):
            return "arrow.turn.up.left"
        case _ where lowercased.contains("right"):
            return "arrow.turn.up.right"
        case _ where lowercased.contains("straight"):
            return "arrow.up"
        case _ where lowercased.contains("over"):
            return "arrow.up"
        default:
            return "mappin.circle.fill" // otherwise display the destination symbol
        }
    }

    
    // Saves the run data to swift data
    func saveRunData(completion: @escaping (Result<Bool, Error>) -> Void) {

        guard runManager.endPlacemark != nil else {
            completion(.success(false))
            return
        }
        
        guard runManager.startPlacemark != nil else {
            completion(.success(false))
            return
        }
        
        var routePNG: Data?
        var breadCrumbPNG: Data?
        
        let dispatchGroup = DispatchGroup()

        if !runManager.isFreeRunning && route != nil {
            dispatchGroup.enter() // Enter DispatchGroup before starting the task

            captureRouteSnapshot { image in
                if let routeImage = image {
                    // convert map image to data
                    let png = routeImage.pngData()
                    if png == nil {
                        let error = NSError(domain: "TaskErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert route image to data"])
                        completion(.failure(error))
                    }
                    
                    routePNG = png
                }
                dispatchGroup.leave()

            }
        }
            
        if runManager.isFreeRunning || runManager.didOptForBreadCrumbTracking {
            dispatchGroup.enter() // Enter DispatchGroup before starting the task

            captureBreadCrumbSnapshot { image in
                if let breadCrumbImage = image {
                    
                    // convert map image to data
                    let png = breadCrumbImage.pngData()
                    if png == nil {
                        let error = NSError(domain: "TaskErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert breadcrumb image to data"])
                        completion(.failure(error))
                    }
                    
                    breadCrumbPNG = png
                }
                dispatchGroup.leave()
            }
        }
        
        
        
        dispatchGroup.notify(queue: .main) {
            
            let newRun = Run(
                isDarkMode: isDarkMode,
                postedDate: Date.now,
                startTime: runManager.runStartTime,
                endTime: runManager.runEndTime,
                elapsedTime: runManager.secondsElapsed,
                distanceTraveled: runManager.distanceTraveled,
                routeDistance: runManager.routeDistance,
                steps: runManager.steps,
                startPlacemark: runManager.startPlacemark!,
                endPlacemark: runManager.endPlacemark!,
                avgSpeed: runManager.averageSpeed,
                avgPace: runManager.averagePace,
                routeImage: routePNG,
                breadCrumbImage: breadCrumbPNG,
                notes: "",
                paceArray: runManager.activePaceArray
            )
            
            // Save the data
            modelContext.insert(newRun)
            do {
                try modelContext.save()
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        }
                
    }
   
    
    
    var body: some View {
        
        GeometryReader { proxy in
            
            NavigationStack {

                ZStack(alignment: .top) {
            
                    MapReader { proxy in
                        
                        // The selection parameter enables swift to emphasize any landmarks the user taps on the map
                        Map(position: $cameraPosition, interactionModes:  interactionModes, selection: $selectedPlaceMark) {
                            
                            UserAnnotation()
                            
                            // Show custom locations by default
                            ForEach(allCustomPinLocations, id: \.self) { pin in
                                if !routeDisplaying {
                                    Marker(pin.name, coordinate: pin.getLocation())
                                        .tint(.yellow)
                                        .tag(pin)
                                }
                            }
                        
                            // Render the route on the map
                            if let route, routeDisplaying {
                                
                                MapPolyline(route.polyline)
                                    .mapOverlayLevel(level: .aboveRoads)
                                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round)) // Light blue border
                                               
                               MapPolyline(route.polyline)
                                    .mapOverlayLevel(level: .aboveRoads)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                               
                            }
                            
                            // Show the breadcrumb path
                            if runStatus == .startedRun && displayBreadCrumbPath  {
                                let points = runManager.locations.map { MKMapPoint($0.coordinate) }
                                MapPolyline(coordinates: points.map { $0.coordinate })
                                    .stroke( runManager.isFreeRunning ? BLUE : LIGHT_BLUE, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            }
                            
                            // The routeDestination is used to persist the marker even when the user taps elsewhere on the screen
                            if let routeDestination {
                                Marker(routeDestination.name, coordinate: routeDestination.getLocation())
                                    .tint(routeDestination.isCustomLocation ? .yellow : .red)
                                    .tag(routeDestination)
                            }
                            
                            // Show all search results if user hasn't selected a place yet
                            if let places = runManager.fetchedPlaces, !places.isEmpty {
                                ForEach(places, id: \.self) { place in
                                    Group {
                                        // Show search results on map if user hasn't selected a destination yet
                                        if !routeDisplaying {
                                            Marker(place.name, coordinate: place.getLocation())
                                                .tint(.red)
                                        }
                                    }.tag(place)
                                }
                            }
                        }
                        .mapFeatureSelectionDisabled { _ in false}
                        .mapFeatureSelectionContent { feature in
                           Marker(feature.title ?? "", coordinate: feature.coordinate)
                       }
                        // Run asynchronous task to fetch route when user selects new destination
                        .task(id: selectedPlaceMark) {
                            if selectedPlaceMark != nil  {
                                usePin = false
                                await fetchRoute()
                                
                                if !disabledFetch {
                                    isTextFieldFocused = false
                                    withAnimation {
                                        routeSheetVisible = true
                                        routeSheetSelectedDetent = SheetPosition.peek.detent
                                    }
                                    
                                    withAnimation {
                                        cameraPosition = .region(MKCoordinateRegion(
                                            center: selectedPlaceMark!.getLocation(),
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        ))
                                    }
                                }
                               
                            }
                        }
                        .ignoresSafeArea(.keyboard)
                        .onMapCameraChange(frequency: .continuous) {
                            isPinActive = true
                        }
                        .onMapCameraChange(frequency: .onEnd) { mapCameraUpdateContext in
                            isPinActive = false
                            pinCoordinates = mapCameraUpdateContext.camera.centerCoordinate
                        }
                        .overlay {
                            if (usePin) {
                                VStack(alignment: .center) {
                                    Spacer()
                                    DraggablePin(isPinActive: $isPinActive)
                                    Spacer()
                                }
                                .ignoresSafeArea(.all)
                            }
                        }
                        .ignoresSafeArea(edges: [.leading, .trailing])
                        .mapStyle(.standard(elevation: .realistic, showsTraffic: false))
                        .mapControls {
                            MapCompass()
                            MapUserLocationButton()
                        }
                    }
                   
                    
                    // Bottom sheet to enable location search and select a destination
                    .sheet(isPresented: $searchPlaceSheetVisible) {
                        ScrollView {
                            VStack(alignment: .leading) {
                                
                                HStack {

                                    VStack(alignment: .center) {
                                        
                                        // Button to run freely while automatically tracking breadcrumbs
                                        Button {
                                           
                                            let hasAccess = (subscriptionManager.hasSubscriptionExpired() && runsThisMonth.count < RUN_LIMIT) ||
                                                (!subscriptionManager.hasSubscriptionExpired())
                                            
                                            if hasAccess {
                                                Task {
                                                    isStartRunLoading = true
                                                    runManager.isFreeRunning = true
                                                    runManager.didOptForBreadCrumbTracking = true
                                                    
                                                    // Save the start location. The end location will depend where the user ends their run
                                                    if let userLocation = runManager.userLocation {
                                                        runManager.lookUpLocation(location: userLocation) { startPlacemark in
                                                            if startPlacemark == nil {
                                                                print("could not reverse geo code user's location")
                                                                return
                                                            }
                                                            runManager.storeRouteDetails(start: startPlacemark!, end: nil, distance: nil)
                                                        }
                                                    }
                                                    
                                                    await runManager.beginRunSession()
                                                    runStatus = .startedRun
                                                    isStartRunLoading = false
                                                    searchPlaceSheetVisible = false
                                                    routeSheetVisible = false
                                                    runSheetVisible = true
                                                }
                                            } else {
                                                showProAccessRunsDialog = true
                                            }
                                        } label: {
                                            HStack {
                                                if isStartRunLoading {
                                                    ProgressView()
                                                        .tint(TEXT_LIGHT_GREEN)
                                                } else {
                                                    Text("Quick start")
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(TEXT_LIGHT_GREEN)
                                                        .font(.subheadline)
                                                }
                                            }
                                            .padding(8)
                                            .frame(width: 108)
                                            .background(LIGHT_GREEN)
                                            .cornerRadius(8)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("Pin", systemImage: usePin ? "mappin.circle.fill" : "mappin.slash.circle.fill", isOn: $usePin)
                                        .tint(.yellow)
                                        .toggleStyle(.button)
                                        .labelStyle(.iconOnly)
                                        .font(.title)
                                    
                                    if(usePin) {
                                        let hasAccess = (allCustomPinLocations.count < PIN_LIMIT && subscriptionManager.hasSubscriptionExpired()) ||  (!subscriptionManager.hasSubscriptionExpired())
                                        Button {
                                            if hasAccess {
                                                addCustomLocation()
                                            } else {
                                                // show pro access dialog
                                                showProAccessPinsDialog = true
                                                
                                            }
                                        } label: {
                                            Image(systemName: hasAccess ? "plus.circle.fill" : "lock")
                                                .frame(width: 48, height: 48)
                                                .foregroundStyle(.white)
                                        }
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .leading).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity))
                                        )
                                        .animation(.easeOut(duration: 0.2), value: usePin)
                                    }
                                    
                                }
                                .frame(height: 54)
                                .padding(.leading, 16)
                                .padding(.trailing, 8)
                                .padding(.bottom, 8)
                                
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .padding(.leading, 8)
                                        .foregroundStyle(.white)
                                    
                                    TextField("", text: Binding(get: { runManager.searchText }, set: { runManager.searchText = $0 }), prompt: Text("Or choose a destination").foregroundColor(.white))
                                        .foregroundStyle(.white)
                                        .autocapitalization(.none)
                                        .frame(height: 48)
                                        .cornerRadius(12)
                                        .padding(.trailing, 8)
                                        .focused($isTextFieldFocused)
                                        .onAppear { UITextField.appearance().clearButtonMode = .always }
                                    
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12).fill(DARK_GREY)
                                )
                                .padding(.horizontal, 16)
                                
                                
                                // Show list of location search results
                                if !runManager.searchText.isEmpty {
                                    
                                    if let places = runManager.fetchedPlaces {
                                        List {
                                            ForEach(places, id: \.self) { place in
                                                
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(place.name)
                                                            .font(.title3.bold())
                                                            .foregroundStyle(.white)
                                                        
                                                        HStack(spacing: 3) {
                                                            
                                                            // Street
                                                            Text(place.thoroughfare)
                                                                .foregroundStyle(.gray)
                                                            
                                                            // City
                                                            Text(place.locality)
                                                                .foregroundStyle(.gray)
                                                            
                                                            // State
                                                            Text(place.administrativeArea)
                                                                .foregroundStyle(.gray)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                // When user taps on a suggested place in the list view, the route details sheet should show up
                                                .onTapGesture {
                                                    selectedPlaceMark = place
                                                    
                                                    // Show the route for the selected destination
                                                    showRoute = true
                                                    isTextFieldFocused = false // hide the keyboard
                                                    
                                                    withAnimation(.easeOut) {
//                                                        searchPlaceSheetSelectedDetent = SheetPosition.peek.detent
                                                        routeSheetSelectedDetent = SheetPosition.peek.detent
                                                    }
                                                    
                                                    // Animate camera movement to selected placemark
                                                    withAnimation {
                                                        cameraPosition = .region(MKCoordinateRegion(
                                                            center: place.getLocation(),
                                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                        ))
                                                    }
                                                }
                                                .listRowInsets(EdgeInsets(top: place == places.first ? 0 : 8, leading: 0, bottom: 8, trailing: 0))
                                            }
                                            .listRowBackground(Color.clear)
                                            .listStyle(.plain)
                                        }
                                        .frame(height: 600)
                                        .scrollContentBackground(.hidden)
                                        .contentMargins(.top, 0)
                                        .padding(.top, 8)
                                    }
                                } else {
                                    // show list of past run suggestions
                                    HStack {
                                        Text("Recent runs")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                    .padding(.horizontal, 20)
                                    
                                    if recentRuns.isEmpty {
                                        VStack(alignment: .center) {
                                            Text("No recent runs")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                                .padding()
                                        }
                                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                                        .frame(height: 80)
                                    }
                                    else {
                                        let uniqueRuns = Dictionary(grouping: recentRuns, by: { $0.endPlacemark!.name })
                                            .compactMap { $0.value.first }
                                            .sorted(by: { $0.endTime > $1.endTime } )
                                        
                                        List {
                                            ForEach(uniqueRuns, id: \.id) { run in
                                                
                                                HStack(alignment: .center) {
                                                    
                                                    let isCustom =  run.endPlacemark!.isCustomLocation
                                                    Image(systemName: "mappin.circle.fill")
                                                        .foregroundStyle(.white, isCustom ?  .yellow : .red )
                                                    
                                                    Text(run.endPlacemark!.name)
                                                        .foregroundStyle(.white)
                                                    
                                                    Spacer()
                                                    
                                                }
                                                .onTapGesture {
                                                    runManager.searchText = run.endPlacemark!.name
                                                    selectedPlaceMark = run.endPlacemark!
                                                    
                                                    // Show the route for the selected destination
                                                    showRoute = true
                                                    isTextFieldFocused = false // hide the keyboard
                                                    
                                                    withAnimation(.easeOut) {
                                                        searchPlaceSheetSelectedDetent = SheetPosition.peek.detent
                                                        routeSheetSelectedDetent = SheetPosition.peek.detent
                                                    }
                                                    
                                                    // Animate camera movement to selected placemark
                                                    withAnimation {
                                                        cameraPosition = .region(MKCoordinateRegion(
                                                            center: run.endPlacemark!.getLocation(),
                                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                        ))
                                                    }
                                                }
                                                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                                                
                                            }
                                            .listRowBackground(Color.clear)
                                            .listStyle(.plain)
                                            .padding(.leading, 8)
                                            .padding(.trailing, 16)
                                        }
                                        .frame(height: 300)
                                        .contentMargins(.top, 0) // removes that annoying top padding above first list item
                                        .scrollContentBackground(.hidden)
                                    }
                                }
                                                                                            
                                Spacer()
                                
                            }
                            .padding(.top, 16)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .presentationDetents(searchPlaceSheetDetents, selection: $searchPlaceSheetSelectedDetent)
                            .presentationBackground(.black)
                            .interactiveDismissDisabled()
                            .presentationBackgroundInteraction(
                                .enabled(upThrough: SheetPosition.full.detent)
                            )
                        }
                        .frame(maxHeight: .infinity)
                        
                        
                        // Route details sheet
                        .sheet(isPresented: $routeSheetVisible, onDismiss: {
                            if runStatus == .planningRoute {
                                removeRoute()
                                disabledFetch = false
                            }
                        }) {
                                              
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading) {
                                    
                                    HStack {
                                        Text("Route Details").font(.title3).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                                        Spacer()
                                        
                                        // Custom dismiss button
                                        Button {
                                            routeSheetVisible = false
                                            removeRoute()
                                            disabledFetch = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.gray)
                                                .font(.title)
                                        }
                                    }
                                    
                                    
                                    if routeDestination != nil {
                                        
                                        Text(routeDestination!.name).font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                                        
                                        HStack(spacing: 16) {
                                            
                                            CapsuleView(background: DARK_GREY, iconName: "timer", iconColor: .white, text: travelTimeString ?? "")
                                            CapsuleView(background: DARK_GREY, iconName: "figure.run", iconColor: .white, text: String(format: "%.1fmi", routeDistance))
                                            
                                                Menu {
                                                    
                                                    if routeDestination!.isCustomLocation {
                                                        Button("Delete custom pin") {
                                                            isShowingDeleteCustomPinDialog = true
                                                        }
                                                        Button("Edit name") { editCustomPinNameSheetVisible = true}
                                                        Button("Past runs") { viewPinAssociatedRunsSheetVisible = true }
                                                    }
                                                    
                                                    Toggle("Trace path for this run", isOn: $runManager.didOptForBreadCrumbTracking )
                                                    Toggle("Best location accuracy", isOn: $runManager.bestLocationAccuracy )


                                                } label: {
                                                    Image(systemName: "ellipsis.circle.fill")
                                                        .font(.largeTitle)
                                                        .foregroundStyle(.white, DARK_GREY) // color the dots white and underlying circle grey
                                                        .rotationEffect(Angle(degrees: 90))
                                                        .padding(2)
                                                }
                                                .alert("Deleting this pin will delete any runs that reference it", isPresented: $isShowingDeleteCustomPinDialog) {
                                                    Button("Delete", role: .destructive) {
                                                        deleteCustomPin()
                                                    }
                                                    
                                                    Button("Cancel", role: .cancel) {}
                                                }
                                            
                                            
                                          
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        
                                        Button {
                                            let hasAccess = (subscriptionManager.hasSubscriptionExpired() && runsThisMonth.count < RUN_LIMIT) ||
                                                (!subscriptionManager.hasSubscriptionExpired())
                                            
                                            if hasAccess {
                                                Task{
                                                    isStartRunLoading = true
                                                    // runManager will save the start and end locations
                                                    if let userLocation = runManager.userLocation {
                                                        runManager.lookUpLocation(location: userLocation) { startPlacemark in
                                                            guard let startPlacemark else {
                                                                print("could not reverse geo code user's location")
                                                                return
                                                            }
                                                            runManager.storeRouteDetails(start: startPlacemark, end: routeDestination!, distance: routeDistance)
                                                        }
                                                    }
                                                    
                                                    await runManager.beginRunSession()
                                                    
                                                    runStatus = .startedRun
                                                    isStartRunLoading = false
                                                    routeSheetVisible = false
                                                    searchPlaceSheetVisible = false
                                                    runSheetVisible = true
                                                }
                                            } else {
                                                showProAccessRunsDialog = true
                                            }
                                            
                                        } label: {
                                            HStack {
                                                if isStartRunLoading {
                                                    ProgressView()
                                                        .tint(TEXT_LIGHT_GREEN)
                                                    
                                                } else {
                                                    Text("Start Run")
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(TEXT_LIGHT_GREEN)
                                                }
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(LIGHT_GREEN)
                                            .cornerRadius(12)
                                        }
                                        
                                        VStack(alignment: .center) {
                                            Image(systemName: "lightbulb.max")
                                                .padding(.vertical, 8)
                                            Text("Your run stats are automatically tracked in the background.").foregroundStyle(TEXT_LIGHT_GREY)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.top, 48)
                                    }
                                }
                                .onAppear {
                                    // Prevents behavior where tapping on a different route destination marker fetches a different route
                                    disabledFetch = true
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .frame(maxHeight: .infinity, alignment: .top)
                                .presentationDetents(routeSheetDetents, selection: $routeSheetSelectedDetent)
                                .presentationBackground(.black)
                                .presentationDragIndicator(.visible)
                                .interactiveDismissDisabled(true)
                                .presentationBackgroundInteraction(
                                    .enabled(upThrough: SheetPosition.full.detent)
                                )
                                
                                // Past runs for pin sheet
                                .sheet(isPresented: $viewPinAssociatedRunsSheetVisible) {
                                    VStack {
                                        HStack {
                                            Text("Past Runs").font(.title2).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                                            Spacer()
                                            
                                            // Custom dismiss button
                                            Button {
                                                viewPinAssociatedRunsSheetVisible = false
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.gray)
                                                    .font(.title)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        
                                        if associatedRuns.count == 0 {
                                            Spacer()
                                            Text("You have not logged any runs for this location.")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 32)
                                            Spacer()
                                        } else {
                                            
                                            // Timeline View of associated runs
                                            ScrollView(showsIndicators: false) {
                                                ForEach(Array(associatedRuns.enumerated()), id: \.element.id) { index, run  in
                                                    
                                                    HStack(alignment: .top, spacing: 12) {
                                                        Circle()
                                                            .fill(BLUE)
                                                            .frame(width: 8, height: 8)
                                                            .overlay(alignment: .top) {
                                                                if associatedRuns.count > 1 && index < associatedRuns.count - 1 {
                                                                    Rectangle()
                                                                        .fill(BLUE.opacity(0.5))
                                                                        .frame(width: 2, height: 56)
                                                                }
                                                                else {
                                                                    Rectangle()
                                                                        .fill(Color.clear)
                                                                }
                                                            }
                                                        
                                                        VStack(alignment: .leading) {
                                                            
                                                            Text(run.startTime.formatted(
                                                                .dateTime
                                                                    .weekday(.abbreviated)
                                                                    .month(.abbreviated)
                                                                    .day()
                                                                    .hour()
                                                                    .minute()
                                                                    .hour(.defaultDigits(amPM: .abbreviated))
                                                            ))
                                                            .font(.subheadline)
                                                            
                                                            
                                                            Text("\(run.steps) steps")
                                                                .font(.caption)
                                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                                        }
                                                        .offset(y: -4)
                                                        
                                                        Spacer()
                                                    }
                                                    .frame(height: 48)
                                                }
                                                .listRowBackground(Color.clear)
                                                .listStyle(.plain)
                                            }
                                            .padding(.horizontal, 16)
                                            .scrollContentBackground(.hidden)
                                        }
                                    }
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    .padding(.top, 16)
                                    .presentationDetents(viewPinAssociatedRunsSheetDetents)
                                    .presentationBackground(.black)
                                    .presentationDragIndicator(.visible)
                                    .presentationBackgroundInteraction(.disabled)
                                }
                                .onAppear {
                                    if routeDestination != nil {
                                        Task {
                                            await fetchAssociatedRunsForPin(pin: routeDestination!)
                                        }
                                    }
                                }
                                
                                
                                // Edit custom pin name sheet
                                .sheet(isPresented: $editCustomPinNameSheetVisible, onDismiss: {
                                    newCustomPinName = ""
                                }) {
                                    ScrollView(showsIndicators: false) {

                                        let oldName = String(routeDestination!.getName())
                                        
                                        VStack(alignment: .leading, spacing: 24) {
                                            
                                            HStack {
                                                Text("Change pin name").font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                                                Spacer()
                                                
                                                // Custom dismiss button
                                                Button {
                                                    editCustomPinNameSheetVisible = false
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.gray)
                                                        .font(.title)
                                                }
                                            }
                                           
                                            TextField("", text: $newCustomPinName, prompt: Text("Enter a new name for \(oldName)").foregroundColor(.white))
                                                .foregroundColor(.white)
                                                .autocapitalization(.none)
                                                .frame(height: 48)
                                                .cornerRadius(12)
                                                .padding(.leading)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12).fill(DARK_GREY)
                                                )
                                        
                                            
                                            Button {
                                               saveNewCustomPinName()
                                            } label: {
                                                HStack {
                                                    Text("Save")
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(TEXT_LIGHT_GREEN)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(LIGHT_GREEN)
                                                .cornerRadius(12)
                                            }
                                            .sensoryFeedback(.success, trigger: isCustomPinNewNameSaved)
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    .padding(.top, 16)
                                    .presentationDetents(editCustomPinNameSheetDetents)
                                    .presentationBackground(.black)
                                    .presentationDragIndicator(.visible)
                                    .presentationBackgroundInteraction(.disabled)
                                    
                                }
                            }
                        }
                    }
                    
                            
                    // Run sheet
                    .sheet(isPresented: $runSheetVisible) {
                        ScrollView(showsIndicators: false) {
                            
                            if routeDestination != nil && !runManager.isFreeRunning {
                                VStack(alignment: .leading) {
                                    
                                    // Header content
                                    HStack {
                                        Text(routeDestination!.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Spacer()

                                    }
                                    
                                    // Display timer and step count
                                    HStack {
                                        HStack{
                                            Image(systemName: "timer")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                             
                                            if let maxEndTime = runManager.maxEndTime {
                                                Text(timerInterval: runManager.runStartTime...maxEndTime, countsDown: false, showsHours: true)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                    .monospacedDigit()
                                            }
                                          
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(DARK_GREY)
                                        .clipShape(Capsule())
                                        
                                        Text("\(runManager.steps) steps")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(DARK_GREY))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer().frame(height: 16)
                                    
                                    
                                    // Button to show route steps in a list view
                                    Button{
                                        stepsSheetVisible = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "map.fill")
                                                .foregroundStyle(TEXT_LIGHT_GREY)

                                            Text("Route Details")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity) // Fills the entire width
                                        .background(DARK_GREY)
                                        .cornerRadius(12) // Rounds the corners
                                    }
                                    
                                    Spacer().frame(height: 16)
                                    
                                    // End run button
                                    EndRunButton(
                                        isFinishRunLoading: $isFinishRunLoading,
                                        isShowingEndRunDialog: $isShowingEndRunDialog,
                                        searchPlaceSheetVisible: $searchPlaceSheetVisible,
                                        stepsSheetVisible: $stepsSheetVisible,
                                        routeSheetVisible: $routeSheetVisible,
                                        runSheetVisible: $runSheetVisible,
                                        showRunView: $showRunView,
                                        runManager: runManager,
                                        saveRunData: saveRunData
                                    )
                                    
                                    Spacer()

                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .presentationDetents(runSheetDetents)
                                .presentationBackground(.black)
                                .presentationDragIndicator(.visible)
                                .interactiveDismissDisabled(true)
                                .presentationBackgroundInteraction(
                                    .enabled(upThrough: .large)
                                )

                            }
                            
                             if runManager.isFreeRunning {
                                VStack {
                                    // Header content
                                    HStack {
                                        Text("Running")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                    }
                                    .padding(.bottom, 8)
                                    
                                    HStack {
                                        HStack{
                                            Image(systemName: "timer")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                             
                                            if let maxEndTime = runManager.maxEndTime {
                                                Text(timerInterval: runManager.runStartTime...maxEndTime, countsDown: false, showsHours: true)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                    .monospacedDigit()
                                            }
                                          
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(DARK_GREY)
                                        .clipShape(Capsule())
                                        
                                        Text("\(runManager.steps) steps")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(DARK_GREY))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer().frame(height: 16)
                                    
                                    // End run button
                                    EndRunButton(
                                        isFinishRunLoading: $isFinishRunLoading,
                                        isShowingEndRunDialog: $isShowingEndRunDialog,
                                        searchPlaceSheetVisible: $searchPlaceSheetVisible,
                                        stepsSheetVisible: $stepsSheetVisible,
                                        routeSheetVisible: $routeSheetVisible,
                                        runSheetVisible: $runSheetVisible,
                                        showRunView: $showRunView,
                                        runManager: runManager,
                                        saveRunData: saveRunData
                                    )

                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .presentationDetents(runSheetDetents)
                                .presentationBackground(.black)
                                .presentationDragIndicator(.visible)
                                .interactiveDismissDisabled(true)
                                .presentationBackgroundInteraction(
                                    .enabled(upThrough: .large)
                                )
                            }
                             
                        }
                        
                        
                        // Route steps sheet
                        .sheet(isPresented: $stepsSheetVisible) {
                            VStack {
                                HStack {
                                    Text("Route Directions").font(.title2).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                                    Spacer()
                                    
                                    // Custom dismiss button
                                    Button {
                                        stepsSheetVisible = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray)
                                            .font(.title)
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                List {
                                    let steps = runManager.routeSteps
                                    // The first route step using autombile transporation type is empty so we skip it
                                    ForEach(1..<steps.count, id: \.self) { idx in
                                        
                                        HStack(alignment: .center, spacing: 16) {
                                        
                                            Image(systemName: sfSymbolForDirection(instruction: steps[idx].instructions))
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(convertMetersToString(distance: steps[idx].distance))")
                                                    .font(.largeTitle)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                
                                                Text("\(steps[idx].instructions)")
                                                    .font(.title2)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                            }
                                            
                                            Spacer()
                                        }
                                        .listRowInsets(EdgeInsets(top: idx == 0 ? 0 : 16, leading: 0, bottom: 16, trailing: 0))
                                    }
                                    .listRowBackground(Color.clear)
                                    .listStyle(.plain)
                                }
                                .contentMargins(.top, 0) // removes that annoying top padding above first list item
                                .scrollContentBackground(.hidden)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 16)
                            .presentationDetents(stepsSheetDetents)
                            .presentationBackground(.black)
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.disabled)
                        }
                       
                    }
                    
                    
                    if (runStatus == .planningRoute) {
                        HStack {
                            Button {
                                // dismiss the run view
                                showRunView = false
                            } label: {
                                ZStack {
                                    Circle()
                                        .frame(width: 32, height: 32)
                                        .foregroundStyle(.black)
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal, 12)
                    }

                    else if (runStatus != .planningRoute && runManager.didOptForBreadCrumbTracking) {
                        HStack {
                            Menu {
                                
                                Section("Breadcrumb Visibility") {
                                    Button { displayBreadCrumbPath.toggle() } label: {
                                        Label("Display Path", systemImage: "checkmark")
                                            .labelStyle(MyLabelStyle(isSelected: displayBreadCrumbPath == true))
                                    }
                                }
                                
                                Section("Breadcrumb Resolution") {
                                    Button { breadCrumbAccuracy = 10 } label: {
                                        Label("10 meters", systemImage: "checkmark")
                                            .labelStyle(MyLabelStyle(isSelected: breadCrumbAccuracy == 10))
                                    }
                                    
                                    Button { breadCrumbAccuracy = 50 } label: {
                                        Label("50 meters", systemImage: "checkmark")
                                            .labelStyle(MyLabelStyle(isSelected: breadCrumbAccuracy == 50))
                                    }
                                    Button { breadCrumbAccuracy = 100 } label: {
                                        Label("100 meters", systemImage: "checkmark")
                                            .labelStyle(MyLabelStyle(isSelected: breadCrumbAccuracy == 100))
                                    }
                                    Button { breadCrumbAccuracy = 500 } label: {
                                        Label("500 meters", systemImage: "checkmark")
                                            .labelStyle(MyLabelStyle(isSelected: breadCrumbAccuracy == 500))
                                    }
                                }
                                                                
                                                               
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(isDarkMode ? .white : .black) // color the dots white and underlying circle grey
                                    .padding(4)
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal, 12)
                    }

                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar(.hidden, for: .navigationBar)
                .toast(isPresenting: $showProAccessPinsDialog, tapToDismiss: true) {
                    AlertToast(type: .systemImage("lock", .white), title: "Get Pro Access to add more pins.")
                }
                .toast(isPresenting: $showProAccessRunsDialog, tapToDismiss: true) {
                    AlertToast(type: .systemImage("lock", .white), title: "Get Pro Access to add more runs.")
                }
                
              
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                runManager.resetUserLocation()
                
                runsThisMonth = recentRuns.filter { run in
                    let calendar = Calendar.current
                    let currentDate = Date()
                    let currentYear = calendar.component(.year, from: currentDate)
                    let currentMonth = calendar.component(.month, from: currentDate)
                    
                    let runYear = calendar.component(.year, from: run.startTime)
                    let runMonth = calendar.component(.month, from: run.startTime)
                    return runYear == currentYear && runMonth == currentMonth
                }
            }
        }
    }
}

/**
 A custom button to end a run session. When triggered, the user is presented with a confirmation dialog to proceed.
 Confirmation will then run a task to end a run and background processes.
 */
struct EndRunButton: View {
    @Binding var isFinishRunLoading: Bool
    @Binding var isShowingEndRunDialog: Bool
    @Binding var searchPlaceSheetVisible: Bool
    @Binding var stepsSheetVisible: Bool
    @Binding var routeSheetVisible: Bool
    @Binding var runSheetVisible: Bool
    @Binding var showRunView: Bool

    // Managers
    var runManager: RunManager
    var saveRunData: (@escaping (Result<Bool, Error>) -> Void) -> Void
    
    var body: some View {
        
        // End run button
        Button  {
            isShowingEndRunDialog = true
        } label: {
            HStack {
                if isFinishRunLoading {
                    ProgressView()
                        .tint(TEXT_LIGHT_RED)
                } else {
                    Text("Finish Run")
                        .fontWeight(.semibold)
                        .foregroundStyle(TEXT_LIGHT_RED)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.red)
            .cornerRadius(12)
        }
        .confirmationDialog("Are you sure?", isPresented: $isShowingEndRunDialog) {
            Button("Yes", role: .destructive) {
                Task {
                    isFinishRunLoading = true
                    
                    await runManager.endRunSession() { success in
                        
                        if !success {
                            print("couldn't end run session at the moment")
                            return
                        }
                        
                        saveRunData { result in
                            
                            switch result {
                            case .success(let status):
                                
                                if !status {
                                    print("didn't find run or start placemarks")
                                    return
                                }
                                searchPlaceSheetVisible = false
                                stepsSheetVisible = false
                                routeSheetVisible = false
                                runSheetVisible = false
                                
                                runManager.clearData()
                                isFinishRunLoading = true
                                showRunView = false
                                
                            case .failure(let error):
                                print("Error saving run data: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
}
