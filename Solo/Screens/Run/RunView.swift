//
//  RunView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//



import Foundation
import SwiftUI
import MapKit
import BottomSheet
import SwiftData


enum RunStatus: String {
    case planningRoute = "planning route", startedRun = "started run", endedRun = "ended run"
}

struct RunView: View {
    
    // Environment objects to handle location and activity monitoring
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    @Environment(\.modelContext) private var modelContext

    // App storage configurations
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("isLiveActivityEnabled") var isLiveActivityEnabled = true

    @State var startedRun: Bool = false
    @State var runStatus: RunStatus = .planningRoute
    @Binding var showRunView: Bool
    
    // Bottom Sheet position states
    @State var searchPlaceSheetPosition: BottomSheetPosition  = .relative(0.20)
    @State var routeSheetPosition: BottomSheetPosition  = .hidden
    @State var runSheetPosition: BottomSheetPosition  = .hidden
    @State var stepsSheetPosition: BottomSheetPosition  = .hidden
    @State var customPinSheetPosition: BottomSheetPosition = .hidden
    
    // Search text field focus state
    @FocusState private var isTextFieldFocused: Bool
    @State var addressInput: String = ""
    
    // Map variables to handle interactions and camera
    @State var interactionModes: MapInteractionModes = [.zoom, .pan, .pitch, .rotate] // gestures for map view
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
    @State private var isShowingDeleteDialog: Bool = false
    
    // Subsequent route fetches are disabled when viewing current route details
    @State private var disabledFetch: Bool = false
    
    // If user has finished saving a run, navigate to run summary view
    @State private var canShowSummary: Bool = false
        
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
            }
            
            travelInterval = route?.expectedTravelTime
            
            if route != nil {
                print("routeDisplaying set to true")
                routeDisplaying = true
                searchPlaceSheetPosition = .relative(0.25)
                routeSheetPosition = .relative(0.25) // show the route detail sheet
                
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

    
    var remainingDistanceToStep: String? {
        guard let remainingDistance = locationManager.remainingDistanceToStep else { return nil }
        
        // Create a distance formatter
        let formatter = MKDistanceFormatter()
        formatter.units = .imperial // units in feet
        
        // Format the remaining distance and return it as a string
        return formatter.string(fromDistance: remainingDistance)
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
        
        // return back to user location if cancelled route
        withAnimation {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }

        
    // Creates a map snapshot image of the user's initial route
    func captureMapSnapshot(completion: @escaping (UIImage?) -> Void) {
        print("setting up map snapshot configs")

        let snapshotOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(route!.polyline.boundingMapRect)
        
        let paddingPercentage: CLLocationDegrees = 0.25 // Adjust percentage for padding
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
        snapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: .dark) // dark mode map

        let snapshotter = MKMapSnapshotter(options: snapshotOptions)

        // start request to create the snapshot image
        snapshotter.start { snapshot, error in

            if let error = error {
                print("Error capturing snapshot: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // draw initial map
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
            context.setLineWidth(6)
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.strokePath()

            print("added mk route polyline")

            // Draw sart and end placemark annotations on the snapshot image
            let startPoint = snapshot!.point(for: locationManager.startPlacemark!.getLocation())
            let startAnnotationImage = UIImage(systemName: "figure.walk.circle.fill")
            startAnnotationImage?.draw(at: CGPoint(x: startPoint.x, y: startPoint.y))

            let endPoint = snapshot!.point(for: locationManager.endPlacemark!.getLocation())
            let endAnnotationImage = UIImage(systemName: "mappin.circle.fill")?.withRenderingMode(.alwaysTemplate)
            let annotationTintColor = UIColor.red
            annotationTintColor.set()
            
            endAnnotationImage?.draw(at: CGPoint(x: endPoint.x, y: endPoint.y))

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
                            name: firstLocation.name,
                            thoroughfare: firstLocation.thoroughfare,
                            subThoroughfare: firstLocation.subThoroughfare,
                            locality: firstLocation.locality,
                            subLocality: firstLocation.subLocality,
                            administrativeArea: firstLocation.administrativeArea,
                            subAdministrativeArea: firstLocation.subAdministrativeArea,
                            postalCode: firstLocation.postalCode,
                            country: firstLocation.country,
                            isoCountryCode: firstLocation.isoCountryCode,
                            longitude: firstLocation.location!.coordinate.longitude,
                            latitude: firstLocation.location!.coordinate.latitude,
                            isCustomLocation: false,
                            timestamp: Date()
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
                $0.endPlacemark.id == routeId
            })
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
            routeSheetPosition = .hidden
            searchPlaceSheetPosition = .relative(0.25)
            removeRoute()
        }
    }
    
    func addCustomLocation() {
        fetchCustomPinLocation() { customPlacemark in
            if let customPlacemark {

                let placemark = MTPlacemark(
                    name: customPlacemark.name,
                    thoroughfare: customPlacemark.thoroughfare,
                    subThoroughfare: customPlacemark.subThoroughfare,
                    locality: customPlacemark.locality,
                    subLocality: customPlacemark.subLocality,
                    administrativeArea: customPlacemark.administrativeArea,
                    subAdministrativeArea: customPlacemark.subAdministrativeArea,
                    postalCode: customPlacemark.postalCode,
                    country: customPlacemark.country,
                    isoCountryCode: customPlacemark.isoCountryCode,
                    longitude: customPlacemark.location!.coordinate.longitude,
                    latitude: customPlacemark.location!.coordinate.latitude,
                    isCustomLocation: true,
                    timestamp: Date()
                )
                
                modelContext.insert(placemark)
                do {
                    try modelContext.save()
                    print("saved custom location")
                } catch {
                    print(error)
                }
                customPinSheetPosition = .relative(0.25)
                usePin = false
            }
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
                    postedDate: Date.now,
                    startTime: activityManager.runStartTime!,
                    endTime: activityManager.runEndTime!,
                    elapsedTime: activityManager.secondsElapsed,
                    distanceTraveled: activityManager.distanceTraveled,
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
                                    Marker(pin.name ?? "Custom Pin", coordinate: pin.getLocation())
                                        .tint(.yellow)
                                        .tag(pin)
                                }
                            }
                        
                            // Render the route on the map
                            if let route, routeDisplaying {
                                MapPolyline(route.polyline).stroke(.blue, lineWidth: 6)
                            }
                            
                            // This is used to persist the marker even when the user taps elsewhere on the screen
                            if let routeDestination {
                                Marker(routeDestination.name!, coordinate: routeDestination.getLocation())
                                    .tint(routeDestination.isCustomLocation ? .yellow : .red)
                                    .tag(routeDestination)
                            }
                            
                            // Show all search results if user hasn't selected a place yet
                            if let places = locationManager.fetchedPlaces, !places.isEmpty {
                                ForEach(places, id: \.self) { place in
                                    Group {
                                        // Show search results on map if user hasn't selected a destination yet
                                        if !routeDisplaying {
                                            Marker(place.name ?? "Unknown", coordinate: place.getLocation())
                                                .tint(.red)
                                        }
                                    }.tag(place)
                                }
                            }
                        }
                        
                        // Run asynchronous task to fetch route when user selects new destination
                        .task(id: selectedPlaceMark) {
                            if selectedPlaceMark != nil  {
                                usePin = false
                                await fetchRoute()
                                isTextFieldFocused = false
                                searchPlaceSheetPosition = .hidden // minimize search sheet
                                routeSheetPosition = .relative(0.25) // show the route detail sheet
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
                        .mapStyle(.standard)
                        .mapControls {
                            MapCompass()
                            MapUserLocationButton()
                        }
                    }
                    
                    VStack {}
                    .navigationDestination(isPresented: $canShowSummary) {
                        RunSummaryView(showRunView: $showRunView).environmentObject(locationManager).environmentObject(activityManager).zIndex(100)
                    }
                    
                    
                    // Bottom sheet to enable location search and select a destination
                    .bottomSheet(
                        bottomSheetPosition: $searchPlaceSheetPosition,
                        switchablePositions: [.relative(0.25), .relative(0.50), .relative(0.80)]
                    ){
                        VStack(alignment: .leading) {
                            
                            HStack {
                                
                                Text("Plan your run!")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Toggle("Pin", systemImage: usePin ? "mappin.circle.fill" : "mappin.slash.circle.fill", isOn: $usePin)
                                    .tint(NEON)
                                    .toggleStyle(.button)
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                                
                                if(usePin) {
                                    Button {
                                        // add pin location to route and show route info sheet
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
                                    .onSubmit {
                                        searchPlaceSheetPosition = .relative(0.50)
                                    }
                                    .focused($isTextFieldFocused)
                                
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(DARK_GREY)
                            )
                            .onChange(of: isTextFieldFocused) { old, new in
                                if isTextFieldFocused {
                                    if searchPlaceSheetPosition != .relative(0.70) {
                                        searchPlaceSheetPosition = .relative(0.70)
                                    }
                                }
                                
                            }
                            
                            // Show list of location search results
                            if let places = locationManager.fetchedPlaces, !places.isEmpty {
                                List {
                                    ForEach(places, id: \.self) { place in
                                        
                                        VStack(alignment: .leading) {
                                            Text(place.name ?? "")
                                                .font(.title3.bold())
                                                .foregroundStyle(.white)
                                            
                                            HStack(spacing: 3) {
                                                
                                                // Street
                                                Text(place.thoroughfare ?? "")
                                                    .foregroundStyle(.gray)
                                                
                                                // City
                                                Text(place.locality ?? "")
                                                    .foregroundStyle(.gray)
                                                
                                                // State
                                                Text(place.administrativeArea != nil ? ", \(place.administrativeArea!)" : "")
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                        // When user taps on a suggested place in the list view, the route details sheet should show up
                                        .onTapGesture {
                                            selectedPlaceMark = place
                                            
                                            // Show the route for the selected destination
                                            showRoute = true
                                            isTextFieldFocused = false // hide the keyboard
                                            
                                            // Animate camera movement to selected placemark
                                            withAnimation {
                                                cameraPosition = .region(MKCoordinateRegion(
                                                    center: place.getLocation(),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                ))
                                            }
                                        }
                                    }
                                    //.listRowInsets(EdgeInsets(top: place == places.first ? 0 : 16, leading: 0, bottom: 16, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .listStyle(.plain)
                                }
                                .scrollContentBackground(.hidden)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .customBackground(Color.black.clipShape(.rect(cornerRadius: 12)))
                    .dragIndicatorColor(.gray)
                    
                    
                    // Route details sheet
                    .bottomSheet(
                        bottomSheetPosition: $routeSheetPosition,
                        switchablePositions: [.relative(0.25), .relative(0.70)]
                    ){
                                                
                        ZStack {
                            
                            VStack(alignment: .leading) {
                                
                                HStack {
                                    Text("Route Details").font(.title3).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                                    Spacer()
                                    
                                    // Custom dismiss button
                                    Button {
                                        routeSheetPosition = .hidden
                                        searchPlaceSheetPosition = .relative(0.25)
                                        removeRoute()
                                        disabledFetch = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray)
                                            .font(.title)
                                    }
                                }
                                
                                
                                if routeDestination != nil {
                                    
                                    Text(routeDestination!.name ?? "").font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                                    
                                    HStack(spacing: 16) {
                                        if routeDestination!.isCustomLocation {
                                            Menu {
                                                Button("Remove custom pin") { deleteCustomPin()}
                                            } label: {
                                                Image(systemName: "ellipsis.circle.fill")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(.white, DARK_GREY) // color the dots white and underlying circle grey
                                                    .rotationEffect(Angle(degrees: 90))
                                            }
                                        }
                                        CapsuleView(capsuleBackground: DARK_GREY, iconName: "timer", iconColor: .white, text: travelTimeString ?? "")
                                        CapsuleView(capsuleBackground: DARK_GREY, iconName: "figure.run", iconColor: .white, text: "2mi")
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    
                                    Button {
                                        Task{
                                            // LocationManager will save the start and end locations
                                            if let userLocation = locationManager.userLocation {
                                                lookUpLocation(location: userLocation) { startPlacemark in
                                                    if startPlacemark == nil {
                                                        print("could not reverse geo code user's location")
                                                        return
                                                    }
                                                    locationManager.updateStartEndPlacemarks(start: startPlacemark!, end: routeDestination!)
                                                }
                                            }
                                            
                                            // Let system settings take over wakefulness of phone
                                            UIApplication.shared.isIdleTimerDisabled = true
                                            await activityManager.startTracking(isLiveActivityEnabled: isLiveActivityEnabled)
                                            runStatus = .startedRun
                                            routeSheetPosition = .hidden
                                            runSheetPosition = .relative(0.25)
                                        }
                                    } label: {
                                        HStack {
                                            Text("Start Run")
                                                .fontWeight(.semibold)
                                                .foregroundStyle(TEXT_LIGHT_GREEN)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(LIGHT_GREEN)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .onAppear {
                                // prevents behavior where tapping on a different route destination marker fetches a different route
                                disabledFetch = true
                            }
                        }
                    }
                    .onDismiss {
                        searchPlaceSheetPosition = .relative(0.25)
                    }
                    .customBackground(Color.black.clipShape(.rect(cornerRadius: 12)))
                    .dragIndicatorColor(.gray)
                   
                    
                    // Run details sheet
                    .bottomSheet(
                        bottomSheetPosition: $runSheetPosition,
                        switchablePositions: [.relative(0.25), .relative(0.70)]
                    ) {
                        
                        if routeDestination != nil {
                            VStack(alignment: .leading) {
                                
                                // Header content
                                HStack {
                                    Text(routeDestination!.name ?? "")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    // Play and pause button for timer
                                    Toggle("", systemImage: !activityManager.isTimerPaused() ? "pause.fill" : "play.fill", isOn: $isPaused)
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
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(LIGHT_GREY)
                                    .clipShape(Capsule())
                                    
                                    Text("\(activityManager.steps) steps")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .background(LIGHT_GREY)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(LIGHT_GREY))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Spacer().frame(height: 16)
                                
                                
                                // Button to show route steps in a list view
                                Button{
                                    stepsSheetPosition = .relative(0.75)
                                } label: {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.trailing, 4)
                                        Text("Route Details")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                        
                                        Spacer()
                                        
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity) // Fills the entire width
                                    .background(LIGHT_GREY)
                                    .cornerRadius(12) // Rounds the corners
                                }
                                
                                Spacer().frame(height: 16)
                                
                                // End run button
                                Button  {
                                    isShowingDeleteDialog = true
                                } label: {
                                    HStack {
                                        Text("Finish Run")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(TEXT_LIGHT_RED)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.red)
                                    .cornerRadius(12)
                                }
                                .confirmationDialog("Are you sure?", isPresented: $isShowingDeleteDialog) {
                                    Button("Yes", role: .destructive) {
                                        Task {
                                            // let system settings take over wakefulness of phone
                                            UIApplication.shared.isIdleTimerDisabled = false
                                            
                                            await activityManager.stopTracking(isLiveActivityEnabled: isLiveActivityEnabled)
                                            saveRunData { result in
                                                
                                                switch result {
                                                case .success(_):
                                                    
                                                    // hide all the sheets since they won't automatically
                                                    // disappear when navigating to summary view
                                                    runSheetPosition = .hidden
                                                    searchPlaceSheetPosition = .hidden
                                                    stepsSheetPosition = .hidden
                                                    routeSheetPosition = .hidden
                                                    
                                                    runStatus = .planningRoute
                                                    locationManager.clearData()
                                                    activityManager.clearData()
                          
                                                    // Toggle flag to navigate to the run summary view
                                                    canShowSummary = true
                                                    
                                                case .failure(let error):
                                                    print("Error saving run data: \(error.localizedDescription)")
                                                    canShowSummary = false
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            
                            Spacer()
                        }
                    }
                    .dragIndicatorColor(.gray)
                    .customBackground(Color.black.clipShape(.rect(cornerRadius: 12)))
                    
                    
                    // Route steps sheet
                    .bottomSheet(
                        bottomSheetPosition: $stepsSheetPosition,
                        switchablePositions: [.relative(0.25), .relative(0.70)]
                    ) {
                        
                        HStack {
                            Text("Route Directions").font(.title2).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
                            Spacer()
                            
                            // Custom dismiss button
                            Button {
                                stepsSheetPosition = .hidden
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                                    .font(.title)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        
                        List {
                            ForEach(0..<locationManager.routeSteps.count, id: \.self) { idx in
                                
                                VStack(alignment: .leading) {
                                    Text("\(convertMetersToString(distance: locationManager.routeSteps[idx].distance))")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    
                                    Text("\(locationManager.routeSteps[idx].instructions)")
                                        .font(.title3)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
//                                .listRowInsets(EdgeInsets(top: idx == 0 ? 0 : 16, leading: 0, bottom: 16, trailing: 0))

                            }
                            .listRowBackground(Color.clear)
                            .listStyle(.plain)
                            
                        }
                        .scrollContentBackground(.hidden)

                    }
                    .customBackground(Color.black.clipShape(.rect(cornerRadius: 12)))
                    .dragIndicatorColor(.gray)
                    
                    
                    if (runStatus == .planningRoute) {
                        HStack {
                            Button {
                                // dismiss the run view
                                showRunView = false
                            } label: {
                                ZStack {
                                    Circle()
                                        .frame(width: 32, height: 32)
                                        .foregroundStyle(.white)
                                    Image(systemName: "chevron.backward")
                                        .foregroundStyle(.black)
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
                        .animation(.spring, value: startedRun)
                        .padding(.horizontal, 12)
                    }
                    
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
                appearance.backgroundColor = UIColor(Color.black.opacity(0.2))
            }
        }
    }
}









//                .toolbar(runStatus == .startedRun ? .hidden : .visible)
//                .navigationBarTitleDisplayMode(.inline) // makes navigation bar narrow
//                .navigationTitle("")



//
//                            .presentationDetents([.fraction(0.10), .large])
//                            .interactiveDismissDisabled(true) // Prevent dismissal with swipe down
//                            .presentationBackgroundInteraction(.enabled) // allows user to interact with map
//                            .presentationBackground(.black)
//
                        
                        
//                            Text(manager.routeSteps.first?.instructions ?? "")
//                            Text(remainingDistanceToStep ?? "")
//
//                            Button {
//                                removeRoute()
//                                routeSheetPosition = .hidden
//                            } label: {
//                                Text("Cancel Route").foregroundStyle(.white)
//                            }
//                            .buttonBorderShape(.capsule)
//                            .background(DARK_GREY)
//


//                        print(pinCoordinates ?? "n/a")

//                        lookUpCurrentLocation() { address in
//                            if selectedPin != nil  {
//                                selectedPin = address
//                                addressInput = selectedPin!.name!
//                            } else {
//                                addressInput = ""
//                            }
//                        }



// custom pin sheet
//                    .bottomSheet(
//                        bottomSheetPosition: self.$customPinSheetPosition,
//                        switchablePositions: [.relative(0.25), .relative(0.50), .relative(0.70)],
//                        headerContent: {
//                            Text("Custom Location").font(.title3).fontWeight(.semibold).padding(.leading, 16).foregroundStyle(TEXT_LIGHT_GREY)
//                        }
//                    ) {
//                        VStack(alignment: .leading){
////
//                            Text(selectedPin.name ?? "")
//                                .font(.title3.bold())
//                                .foregroundStyle(.white)
//
//                            HStack(spacing: 3) {
//
//                                // Street
//                                Text(selectedPin!.thoroughfare ?? "")
//                                    .foregroundStyle(.gray)
//
//                                // City
//                                Text(selectedPin!.locality ?? "")
//                                    .foregroundStyle(.gray)
//
//                                // State
//                                Text(selectedPin!.administrativeArea != nil ? ", \(selectedPin!.administrativeArea!)" : "")
//                                    .foregroundStyle(.gray)
//                            }
////
//                            Button  {
////                                modelContext.delete(selectedPin!)
////                                selectedPin = nil
//                            } label: {
//                                HStack {
//                                    Text("Add custom location")
//                                        .fontWeight(.semibold)
//                                        .foregroundStyle(.white)
//                                }
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(DARK_GREY)
//                                .cornerRadius(12)
//                            }
//
//                        }
//                    }
//                    .customBackground(Color.black.clipShape(.rect(cornerRadius: 12)))
//                    .showCloseButton(true)
//                    .onDismiss {
//                        // when user closes route detail sheet, clear the route data
//                        selectedPin = nil
//                    }
//
