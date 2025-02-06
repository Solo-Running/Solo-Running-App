//
//  EditCustomPinsView.swift
//  Solo
//
//  Created by William Kim on 11/8/24.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit
import BottomSheet


struct EditCustomPinsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @Binding var showView: Bool

    @Query(filter: #Predicate<MTPlacemark> { place in
        return place.isCustomLocation == true
    },sort: \MTPlacemark.timestamp, order: .reverse) var allCustomPinLocations: [MTPlacemark]
    
    @State var interactionModes: MapInteractionModes = [.zoom, .pan, .pitch, .rotate] // gestures for map view
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    
    @State var allPinsSheetVisible: Bool = true
    @State var pinDetailsSheetVisible: Bool = false
    @State var editCustomPinNameSheetVisible: Bool = false
    @State var viewPinAssociatedRunsSheetVisible: Bool = false

    @State private var allPinsSheetDetents: Set<PresentationDetent> =  [.fraction(0.25), .medium, .large]
    @State private var pinDetailsSheetDetents: Set<PresentationDetent> =  [.fraction(0.25), .medium, .large]
    @State private var editCustomPinNameSheetDetents: Set<PresentationDetent> = [.medium, .large]
    @State private var viewPinAssociatedRunsSheetDetents: Set<PresentationDetent> = [.medium, .large]
    
    @State var selectedPlaceMark: MTPlacemark?
    @State var pinData: MTPlacemark?
    @State var isPinActive: Bool = false
    @State var pinCoordinates: CLLocationCoordinate2D?
    @State var usePin: Bool = false
    
    @State var newCustomPinName: String = ""
    @State private var isCustomPinNewNameSaved: Bool = false
        
    @State var associatedRuns: [Run] = []
    @State var isLoadingAssociatedRuns: Bool = false

    
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
    
    
    func saveNewCustomPinName() {
        isCustomPinNewNameSaved = false
        if !newCustomPinName.isEmpty {
            pinData!.name = newCustomPinName
            isCustomPinNewNameSaved = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                newCustomPinName = ""
                isCustomPinNewNameSaved = false
            }
        }
    }
    
    // When deleting a custom location, delete all runs that reference the location
    func deleteCustomPin() {
        
        if let pinData, pinData.isCustomLocation {

            let id = pinData.id
            let fetchDescriptor = FetchDescriptor<Run>(predicate: #Predicate<Run> {
                $0.endPlacemark?.id == id
            })
            do {
                let runs = try modelContext.fetch(fetchDescriptor)
                for run in runs {
                    modelContext.delete(run)
                }
            } catch {
                print("could not fetch runs with custom pin")
            }
            
            modelContext.delete(pinData)
            selectedPlaceMark = nil
        }
    }

    
    var body: some View {
        NavigationStack {
            
            ZStack(alignment: .top) {
                
                MapReader { proxy in
                    
                    // The selection parameter enables swift to emphasize any landmarks the user taps on the map
                    Map(position: $cameraPosition, interactionModes:  interactionModes, selection: $selectedPlaceMark) {
                        
                        UserAnnotation()
                        
                        // Show custom locations by default
                        ForEach(allCustomPinLocations, id: \.self) { pin in
                            Marker(pin.name , coordinate: pin.getLocation())
                                .tint(.yellow)
                                .tag(pin)
                            
                        }
                    }
                    
                    .task(id: selectedPlaceMark) {
                        if selectedPlaceMark != nil {
                            withAnimation(.easeOut) {
                                pinData = selectedPlaceMark
                                allPinsSheetVisible = false
                                pinDetailsSheetVisible = true
                            }
                            
                            // move to the corresponding pin on the map if the user taps on a list entry
                            withAnimation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: pinData!.getLocation(),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                ))
                            }
                        }
                    }
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
                    .ignoresSafeArea(.keyboard)
                    .ignoresSafeArea(edges: [.leading, .trailing])
                    .mapStyle(.standard)
                    .mapControls {
                        MapCompass()
                        MapUserLocationButton()
                    }
                }
                
                
                // List of all custom pins
                .sheet(isPresented: $allPinsSheetVisible) {
                        VStack {
                            HStack {
                                
                                Text("All Locations")
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
                            .padding([.leading], 16)
                            .padding([.trailing], 8)
                            
                            
                            if !allCustomPinLocations.isEmpty {
                                List {
                                    ForEach(allCustomPinLocations, id: \.self) { pin in
                                        VStack(alignment: .leading) {
                                            Text(pin.name)
                                                .font(.title3.bold())
                                                .foregroundStyle(.white)
                                            
                                            HStack(spacing: 3) {
                                                
                                                // Street
                                                Text(pin.thoroughfare)
                                                    .foregroundStyle(.gray)
                                                
                                                // City
                                                Text(pin.locality)
                                                    .foregroundStyle(.gray)
                                                
                                                // State
                                                Text(pin.administrativeArea)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                        .onTapGesture {
                                            
                                            selectedPlaceMark = pin
                                            pinData = pin
                                            
                                            withAnimation(.easeOut) {
                                                allPinsSheetVisible = false
                                                pinDetailsSheetVisible = true
                                            }
                                            
                                            // move to the corresponding pin on the map if the user taps on a list entry
                                            withAnimation {
                                                cameraPosition = .region(MKCoordinateRegion(
                                                    center: pinData!.getLocation(),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                ))
                                            }
                                        }
                                        .listRowInsets(EdgeInsets(top: pin == allCustomPinLocations.first ? 0 : 16, leading: 0, bottom: 16, trailing: 0))
                                        
                                    }
                                    .listRowBackground(Color.clear)
                                    .listStyle(.plain)
                                }
                                .scrollContentBackground(.hidden)
                            }
                            
                            else {
                                ScrollView(showsIndicators: false) {
                                    ContentUnavailableView(
                                        "No pinned locations were found",
                                        systemImage: "exclamationmark.magnifyingglass",
                                        description: Text("You can add new pins using the pin icon above. ")
                                    )
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .interactiveDismissDisabled(true)
                        .presentationDetents(allPinsSheetDetents) //selection: $allPinsSheetSelectedDetent)
                        .presentationBackground(.black)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)                    
                             
                }
                
                
                // Selected pin details sheet
                .sheet(isPresented: $pinDetailsSheetVisible) {
                    ScrollView(showsIndicators: false){
                        VStack(alignment: .leading) {
                            
                            HStack(alignment: .top) {
                               
                                if pinData != nil {
                                    VStack(alignment: .leading) {
                                        Text(pinData?.name ?? "").font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                                        
                                        HStack(spacing: 3) {
                                            
                                            // Street
                                            Text(pinData?.thoroughfare ?? "")
                                                .foregroundStyle(.gray)
                                            
                                            // City
                                            Text(pinData?.locality ?? "")
                                                .foregroundStyle(.gray)
                                            
                                            // State
                                            Text(pinData?.administrativeArea ?? "")
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                                
                                
                                Spacer()
                                
                                // Custom dismiss button
                                Button {
                                    selectedPlaceMark = nil
                                    pinData = nil
                                    pinDetailsSheetVisible = false
                                    allPinsSheetVisible = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray)
                                        .font(.title)
                                }
                            }
                            .padding(.bottom, 16)
                            
                            if pinData != nil {
                                VStack(spacing: 16) {
                                    
                                    Button  {
                                        Task {
                                            await fetchAssociatedRunsForPin(pin: pinData!)
                                            viewPinAssociatedRunsSheetVisible = true
                                        }
                                        
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Text("Past Runs")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(DARK_GREY)
                                        .cornerRadius(12)
                                    }
                                    
                                    
                                    Button  {
                                        editCustomPinNameSheetVisible = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "pencil")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Text("Edit Name")
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(DARK_GREY)
                                        .cornerRadius(12)
                                    }
                                    
                                    
                                    
                                    Button  {
                                        deleteCustomPin()
                                        selectedPlaceMark = nil
                                        pinData = nil
                                        allPinsSheetVisible = true
                                        pinDetailsSheetVisible = false
                                        
                                    } label: {
                                        HStack {
                                            Text("Delete Pin")
                                                .fontWeight(.semibold)
                                                .foregroundStyle(TEXT_LIGHT_RED)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(.red)
                                        .cornerRadius(12)
                                    }
                                    
                                    
                                    VStack(alignment: .center) {
                                        Image(systemName: "trash")
                                            .padding(.vertical, 8)
                                        
                                        Text("Deleting a custom pin will also delete any runs that reference it.").foregroundStyle(TEXT_LIGHT_GREY)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 16)
                                        
                                    }
                                    .padding(.top, 48)
                                }
                            }
                            else {
                                HStack {
                                    Spacer()
                                    Text("Could not load the pin data. Please retry")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    Spacer()
                                }
                            }
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .interactiveDismissDisabled(true)
                        .presentationDetents(pinDetailsSheetDetents) //, selection: $pinDetailsSheetSelectedDetent)
                        .presentationBackground(.black)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                    }
                    
                    
                    // Edit custom pin name sheet
                    .sheet(isPresented: $editCustomPinNameSheetVisible, onDismiss: {
                        newCustomPinName = ""
                    }) {
                        ScrollView(showsIndicators: false) {

                            let oldName = String(pinData!.getName())
                            
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
                   
                }
                   
                
                
                HStack {
                    Button {
                        // dismiss the edit custom pins view
                        showView = false
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
                    
                    Text("Edit Custom Pins")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    Text("").frame(width: 32, height: 32)
                }
                .padding(.horizontal, 12)
                
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            
            // There's a weird bug where SwiftUI will render the map user annotations and
            // buttons as completely white. This is required to override that behavior
            .tint(.blue)
        }
        
    }
}

