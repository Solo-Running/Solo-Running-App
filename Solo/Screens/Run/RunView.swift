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

enum RunStatus: String {
    case planningRoute = "planning route", startedRun = "started run", endedRun = "ended run"
}

enum SheetPosition: CGFloat, CaseIterable {
    case peek = 0.25
    case detailed = 0.50
    case full = 1.0

    var detent: PresentationDetent {
        .fraction(rawValue)
    }
    static let detents = Set(SheetPosition.allCases.map { $0.detent })
}

/**
 Renders an interactive map using MapKit that enables pan, zoom, and rotate gestures. Users can find specific locations
 using a search bar with matching results appearing as Markers on the map. Custom pins can also be added by dragging a
 pin around the region. A sheet will appear for displaying a run session with realtime data broadcasted to the user and
 a LiveActivity Widget if enabled.  When a user is done, the view will process a MapSnapshot of the route along with the recorded run data.
 */
struct RunView: View {
    
    // Environment objects to handle music, location, and activity monitoring
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
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
    
    // Tracks if timer is paused or playing
    @State private var isPaused: Bool = false
    
    // Confirmation dialog to end the run
    @State private var isShowingEndRunDialog: Bool = false
    
    // Confirmation dialog to delete a custom pin
    @State private var isShowingDeleteCustomPinDialog: Bool = false
    
    // Subsequent route fetches are disabled when viewing current route details
    @State private var disabledFetch: Bool = false
    
    // If user has finished saving a run, navigate to run summary view
    @State private var canShowSummary: Bool = false
        
    @State private var isCustomPinNewNameSaved: Bool = false
        
    
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
        
        if disabledFetch {
            print("route fetch disabled")
            return
        }
        
        if let userLocation = locationManager.userLocation, let selectedPlaceMark {
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
                locationManager.updateStepCoordinates(steps: route.steps)
                travelInterval = route.expectedTravelTime
                
                let destinationLocation = CLLocation(latitude: routeDestination!.latitude, longitude: routeDestination!.longitude)
                routeDistance =  Double(route.distance) / 1609.34 //locationManager.userLocation!.distance(from: destinationLocation)

                print("routeDisplaying set to true")
                routeDisplaying = true
                routeSheetVisible = true
            }
        }
        
        
    }
    
    
    func fetchCustomPinLocation(completionHandler: @escaping (CLPlacemark?) -> Void){
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: pinCoordinates!.latitude, longitude: pinCoordinates!.longitude)
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print("Failed to retrieve address")
                completionHandler(nil)
            }
            if let placemarks = placemarks, let placemark = placemarks.first {
                print("Retrieved address")
               completionHandler(placemark)
            }
            else{
                print("No Matching Address Found")
                completionHandler(nil)
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
    
    func saveNewNameForPin() {
        
    }
    
    // Removes a route when user dismisses the details sheet
    func removeRoute() {
        routeDisplaying = false
        showRoute = false
        route = nil
        selectedPlaceMark = nil
        routeDestination = nil
        disabledFetch = false
        
        locationManager.stepCoordinates.removeAll()
        locationManager.routeSteps.removeAll()
        
    }

        
    // Creates a map snapshot image of the user's initial route
    func captureMapSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("setting up map snapshot configs")

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

        snapshotOptions.size =  CGSize(width: 500, height: 500)
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
            context.setLineWidth(10)
            context.setLineCap(.round)
            context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.8).cgColor)
            context.strokePath()
            print("added mk route polyline")

            // Set up the start placemark annotation image
            let startPoint = snapshot!.point(for: locationManager.startPlacemark!.getLocation())
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
            let endPoint = snapshot!.point(for: locationManager.endPlacemark!.getLocation())
            let endAnnotationTintColor = locationManager.endPlacemark!.isCustomLocation ? UIColor.systemYellow : UIColor.systemRed
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
        fetchCustomPinLocation() { customPlacemark in
            if let customPlacemark {

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

        captureMapSnapshot { image in

            if let image = image {
                // convert map image to data
                let data = image.pngData()

                if data == nil {
                    let error = NSError(domain: "TaskErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])
                    completion(.failure(error))
                }

                let newRun = Run(
                    isDarkMode: isDarkMode,
                    postedDate: Date.now,
                    startTime: activityManager.runStartTime!,
                    endTime: activityManager.runEndTime!,
                    elapsedTime: activityManager.secondsElapsed,
                    distanceTraveled: activityManager.distanceTraveled,
                    routeDistance: locationManager.routeDistance,
                    steps: activityManager.steps,
                    startPlacemark: locationManager.startPlacemark!,
                    endPlacemark: locationManager.endPlacemark!,
                    avgSpeed: activityManager.averageSpeed,
                    avgPace: activityManager.averagePace,
                    routeImage: data!
                )

                // Save the data
                modelContext.insert(newRun)
                do {
                    try modelContext.save()
                    completion(.success(true))
                } catch {
                     completion(.failure(error))
                }
                
            } else {
                let error = NSError(domain: "TaskErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Map image wasn't created properly"])
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
                                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 12, lineCap: .round)) // Light blue border
                                               
                               MapPolyline(route.polyline)
                                    .mapOverlayLevel(level: .aboveRoads)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                
                            }
                            
                            // The routeDestination is used to persist the marker even when the user taps elsewhere on the screen
                            if let routeDestination {
                                Marker(routeDestination.name, coordinate: routeDestination.getLocation())
                                    .tint(routeDestination.isCustomLocation ? .yellow : .red)
                                    .tag(routeDestination)
                            }
                            
                            // Show all search results if user hasn't selected a place yet
                            if let places = locationManager.fetchedPlaces, !places.isEmpty {
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
                                        searchPlaceSheetVisible = false
                                        routeSheetVisible = true
                                        routeSheetSelectedDetent = SheetPosition.peek.detent
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
                        .mapStyle(.standard(elevation: .realistic, showsTraffic: true))
                        .mapControls {
                            MapCompass()
                            MapUserLocationButton()
                        }
                    }
                   
                    
                    // Bottom sheet to enable location search and select a destination
                    .sheet(isPresented: $searchPlaceSheetVisible) {
                        VStack(alignment: .leading) {
                            
                            HStack {
                                Text("Plan your run!")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Toggle("Pin", systemImage: usePin ? "mappin.circle.fill" : "mappin.slash.circle.fill", isOn: $usePin)
                                    .tint(.yellow)
                                    .toggleStyle(.button)
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                                
                                if(usePin) {
                                    Button {
                                        addCustomLocation()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
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
                            .padding(.leading, 16)
                            .padding(.trailing, 8)
                            
                            
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .padding(.leading, 8)
                                    .foregroundStyle(.white)
                                
                                TextField("", text: Binding(get: { locationManager.searchText }, set: { locationManager.searchText = $0 }), prompt: Text("Set your destination").foregroundColor(.white))
                                    .foregroundStyle(.white)
                                    .autocapitalization(.none)
                                    .frame(height: 48)
                                    .cornerRadius(12)
                                    .padding(.trailing, 8)
                                    .focused($isTextFieldFocused)
                                
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(DARK_GREY)
                            )
                            .padding(.horizontal, 16)
 
                            
                            // Show list of location search results
                            if let places = locationManager.fetchedPlaces, !places.isEmpty {
                                List {
                                    ForEach(places, id: \.self) { place in
                                        
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
                                        // When user taps on a suggested place in the list view, the route details sheet should show up
                                        .onTapGesture {
                                            selectedPlaceMark = place
                                            
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
                                                    center: place.getLocation(),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                ))
                                            }
                                        }
                                        .listRowInsets(EdgeInsets(top: place == places.first ? 0 : 8, leading: 0, bottom: 8, trailing: 0))
                                    }
                                    .listRowBackground(Color.clear)
                                    .listStyle(.plain)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 16)
                                }
                                .scrollContentBackground(.hidden)
                            }
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
                    
                    
                    // Route details sheet
                    .sheet(isPresented: $routeSheetVisible, onDismiss: {
                        removeRoute()
                        disabledFetch = false
                    }) {
                                          
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                
                                HStack {
                                    Text("Route Details").font(.title3).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                                    Spacer()
                                    
                                    // Custom dismiss button
                                    Button {
                                        routeSheetVisible = false
                                        searchPlaceSheetVisible = true
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
                                        
                                        if routeDestination!.isCustomLocation {
                                            Menu {
                                                Button("Delete custom pin") {
                                                    isShowingDeleteCustomPinDialog = true
                                                }
                                                
                                                Button("Edit name") { editCustomPinNameSheetVisible = true}
                                                
                                                Button("Past runs") { viewPinAssociatedRunsSheetVisible = true }

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
                                        }
                                      
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    
                                    Button {
                                        Task{
                                            isStartRunLoading = true
                                            // LocationManager will save the start and end locations
                                            if let userLocation = locationManager.userLocation {
                                                lookUpLocation(location: userLocation) { startPlacemark in
                                                    if startPlacemark == nil {
                                                        print("could not reverse geo code user's location")
                                                        return
                                                    }
                                                    locationManager.storeRouteDetails(start: startPlacemark!, end: routeDestination!, distance: routeDistance)
                                                }
                                            }
                                            
                                            // Make the app stay awake during run session
                                            UIApplication.shared.isIdleTimerDisabled = true
                                            await activityManager.beginRunSession()
                                            locationManager.beginTracking()
                                            
                                            runStatus = .startedRun
                                            isStartRunLoading = false
                                            routeSheetVisible = false
                                            runSheetVisible = true
                                            
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
                                        Text("To track your stats, keep your phone awake while running.").foregroundStyle(TEXT_LIGHT_GREY)
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

                                    
                    
                    
                    // Run sheet
                    .sheet(isPresented: $runSheetVisible){
                        ScrollView(showsIndicators: false) {
                            
                            if routeDestination != nil {
                                VStack(alignment: .leading) {
                                    
                                    // Header content
                                    HStack {
                                        Text(routeDestination!.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        // Play and pause button for timer
                                        Toggle("", systemImage: !activityManager.isTimerPaused() ? "pause.fill" : "play.fill", isOn: $isPaused)
                                            .transaction { transaction in
                                                transaction.animation = nil
                                            }
                                            .tint(.white)
                                            .toggleStyle(.button)
                                            .labelStyle(.iconOnly)
                                            .font(.title)
                                            .onChange(of: isPaused) { old, new in
                                                if new {
                                                    activityManager.pauseTimer()
                                                } else {
                                                    activityManager.resumeTimer()
                                                }
                                            }
                                    }
                                    
                                    // Display timer and step count
                                    HStack {
                                        HStack{
                                            Image(systemName: "timer")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Text("\(activityManager.formattedDuration)")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                                .monospacedDigit()
                                                .transaction { transaction in
                                                    transaction.animation = nil
                                                }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(DARK_GREY)
                                        .clipShape(Capsule())
                                        
                                        Text("\(activityManager.steps) steps")
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
                                        locationManager: locationManager,
                                        activityManager: activityManager,
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
                                    let steps = locationManager.routeSteps
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
                                .padding(0)
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
                            
                            Text("Add a run")
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(isDarkMode ? .white : .black)
                            
                            Spacer()
                            
                            Text("").frame(width: 32, height: 32)
                        }
                        .padding(.horizontal, 12)
                    }

                }
              
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden)
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
    var locationManager: LocationManager
    var activityManager: ActivityManager
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
                    // let system settings take over wakefulness of phone
                    UIApplication.shared.isIdleTimerDisabled = false
                    
                    await activityManager.endRunSession()
                    saveRunData { result in
                        
                        switch result {
                        case .success(_):
                            
                            searchPlaceSheetVisible = false
                            stepsSheetVisible = false
                            routeSheetVisible = false
                            runSheetVisible = false
                            
                            locationManager.clearData()
                            locationManager.terminateTracking()
                            
                            activityManager.clearData()
                            
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
