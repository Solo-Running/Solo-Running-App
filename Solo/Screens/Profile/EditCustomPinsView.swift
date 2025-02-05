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
    
    @State private var allPinsSheetSelectedDetent: PresentationDetent = SheetPosition.peek.detent
    @State private var pinDetailsSheetSelectedDetent: PresentationDetent = SheetPosition.peek.detent

    @State private var allPinsSheetDetents: Set<PresentationDetent> =  [.fraction(0.25), .medium, .large]
    @State private var pinDetailsSheetDetents: Set<PresentationDetent> =  [.fraction(0.25), .medium, .large]

    
    @State var selectedPlaceMark: MTPlacemark?
    @State var pinData: MTPlacemark?
    @State var isPinActive: Bool = false
    @State var pinCoordinates: CLLocationCoordinate2D?
    @State var usePin: Bool = false
    
    
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
                            Marker(pin.name ?? "Custom Pin", coordinate: pin.getLocation())
                                .tint(.yellow)
                                .tag(pin)
                            
                        }
                    }
                    
                    .task(id: selectedPlaceMark) {
                        if selectedPlaceMark != nil {
                            pinData = selectedPlaceMark
                            
                            allPinsSheetVisible = false
                            
                            withAnimation(.easeOut) {
                                allPinsSheetVisible = false
                                pinDetailsSheetVisible = true
                                pinDetailsSheetSelectedDetent = SheetPosition.peek.detent
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
                                                pinDetailsSheetSelectedDetent = SheetPosition.peek.detent
                                            }
                                            
                                            // move to the corresponding pin on the map if the user taps on a list entry
                                            withAnimation {
                                                cameraPosition = .region(MKCoordinateRegion(
                                                    center: pin.getLocation(),
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
                        .presentationDetents(allPinsSheetDetents, selection: $allPinsSheetSelectedDetent)
                        .presentationBackground(.black)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)                    
                             
                }
                
                
                
                .sheet(isPresented: $pinDetailsSheetVisible) {
                    ScrollView(showsIndicators: false){
                        VStack(alignment: .leading) {
                            
                            HStack {
                                Text("Pin Details").font(.title3).fontWeight(.semibold).foregroundStyle(TEXT_LIGHT_GREY)
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
                            .padding(.bottom, 8)
                            
                            if pinData != nil {
                                
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
                                
                                Spacer().frame(height: 24)
                                
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
                                    
                                }
                                .padding(.top, 48)
                            }
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .interactiveDismissDisabled(true)
                        .presentationDetents(pinDetailsSheetDetents, selection: $pinDetailsSheetSelectedDetent)
                        .presentationBackground(.black)
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
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
                                .foregroundStyle(.white)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.black)
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

