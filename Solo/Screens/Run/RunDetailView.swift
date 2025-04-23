//
//  RunDetailView.swift
//  Solo
//
//  Created by William Kim on 10/28/24.
//

import Foundation
import SwiftUI
import SwiftData
import Charts

struct ExportableImageCard: View {
    var image: UIImage?
    var runData: Run
    
    var body: some View {
        
        
        VStack {
            
            ZStack(alignment: .topTrailing) {
                if let routeImage = image {
                    Image(uiImage: routeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 600, height: 600)
                }
                else {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "photo.fill")
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Text("No image was found")
                            .font(.subheadline)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 600)
                }
                
                HStack {
                    Spacer()
                    
                    if runData.isDarkMode {
                        Image("SoloText")
                            .resizable()
                            .frame(width: 120, height: 28)
                    } else {
                        Image("SoloText")
                            .resizable()
                            .frame(width: 120, height: 28)
                            .colorInvert()
                    }
                }
                .padding(16)
            }
            
            
            HStack(alignment: .center) {
                                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.subheadline)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                    
                    Text(formattedElapsedTime(from: runData.startTime, to: runData.endTime) )
                        .font(.title)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps")
                        .font(.subheadline)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                    
                    Text("\(runData.steps)")
                        .font(.title)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Miles")
                        .font(.subheadline)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                    
                    Text(String(format:"%.2f mi", runData.distanceTraveled / 1609.344))
                        .font(.title)
                        .foregroundStyle(runData.isDarkMode ? .white : .black)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
        }
        .frame(width: 600)
        .background(Rectangle().fill(runData.isDarkMode ? .black : .white))
    }
}



/**
 Displays a user's previous run session with statistics like time, steps, distance, and average pace.
 Users also have the ability to add notes for the run.
 */
struct RunDetailView: View {
    
    var runData: Run!

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isShowingExpanded: Bool = false
    @Namespace var namespace
    
    @FocusState private var notesIsFocused: Bool
    @State private var paceInformationSheetDetents: Set<PresentationDetent> = [.fraction(0.35), .large]
    @State private var isShowingPaceInformationSheet: Bool = false
    @State private var selectedTime: Int?
    
    @State private var routeTabItems: [String] = []
    @State private var showDeleteDialog: Bool = false
    @Binding var showRunDetailView: Bool
    
    let numberOfPaceMarks: Int = 5
    
    var routeImageData: UIImage? {
        guard let imageData = runData?.routeImage else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    var breadCrumbImageData: UIImage? {
        guard let imageData = runData?.breadCrumbImage else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    var routeImageForShare: Image? {
        guard let uiImage = routeImageData else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    
    private var selectedPaceForTime: Pace? {
        guard let selectedTime else { return nil }
        return runData.paceArray?.first {
            $0.timeSeconds == selectedTime
        }
    }
    
    @MainActor func exportedRouteImage() -> Image {
        let renderer = ImageRenderer(content: ExportableImageCard(image: routeImageData, runData: runData))
        renderer.scale = UIScreen.main.scale
        return Image(uiImage: renderer.uiImage!.withBackground(color: .clear))
    }
 
    @MainActor func exportedBreadCrumbImage() -> Image {
        let renderer = ImageRenderer(content: ExportableImageCard(image: breadCrumbImageData, runData: runData))
        renderer.scale = UIScreen.main.scale
        return Image(uiImage: renderer.uiImage!.withBackground(color: .clear))
    }
    
    
    func generateRandomPaceArray() -> Array<Pace> {
        var paceArray: [Pace] = []
        var currentTime = 0
        let totalTime = 3600 // seconds

        while currentTime < totalTime {
            let randomInterval = 1 //rInt.random(in: 2...5)
            currentTime += randomInterval
            
            if currentTime > totalTime { break }
            
            let paceInSecondsPerMeter = Int.random(in: 0...6) // Adjust as needed
            let pace = Pace(pace: paceInSecondsPerMeter, timeSeconds: currentTime)
            paceArray.append(pace)
        }
        
        return paceArray
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !isShowingExpanded {
                    ScrollView(showsIndicators: false) {
                        
                        // Run statistics section
                        VStack(alignment: .leading) {
                            
                            HStack(alignment: .center) {
                                
                                CapsuleView(background: DARK_GREY, iconName: "timer", iconColor: .white, text: formattedElapsedTime(from: runData.startTime, to: runData.endTime) )
                                
                                Spacer()
                                
                                Text("\(convertDateToTime(date: runData.startTime)) - \(convertDateToTime(date: runData.endTime))")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            
                            
                            // Total Steps Card
                            VStack(alignment: .leading) {
                                
                                HStack(alignment: .center, spacing: 16) {
                                    
                                    // Icon Container
                                    VStack {
                                        Image(systemName: "shoeprints.fill")
                                    }
                                    .frame(width: 48, height: 48)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(LIGHT_GREY))
                                    
                                    
                                    VStack(alignment: .leading) {
                                        Text("Total Steps")
                                            .font(.subheadline)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                        
                                        Text("\(runData!.steps) steps")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                
                            }
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            .padding(.top, 4)
                            
                            
                            // Total Distance Card
                            VStack(alignment: .leading) {
                                
                                HStack(alignment: .center, spacing: 16) {
                                    
                                    // Icon Container
                                    VStack {
                                        Image(systemName: "ruler.fill")
                                    }
                                    .frame(width: 48, height: 48)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(LIGHT_GREY))
                                    
                                    VStack(alignment: .leading) {
                                        Text("Total Distance")
                                            .font(.subheadline)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                        
                                        Text(String(format:"%.2f mi", runData.distanceTraveled / 1609.344))
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                
                            }
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            .padding(.vertical, 4)
                            
                            // Average Pace Card
                            VStack(alignment: .leading) {
                                
                                HStack(alignment: .center, spacing: 16) {
                                    
                                    // Icon Container
                                    VStack {
                                        Image(systemName: "figure.run")
                                    }
                                    .frame(width: 48, height: 48)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(LIGHT_GREY))
                                    
                                    VStack(alignment: .leading) {
                                        
                                        HStack(alignment: .center) {
                                            Text("Average Pace")
                                                .font(.subheadline)
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                            
                                            Spacer()
                                            
                                            Button {
                                                isShowingPaceInformationSheet = true
                                            } label: {
                                                Image(systemName: "eye.fill")
                                                    .font(.subheadline)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                            }
                                        }
                                        
                                        Text("\(runData!.avgPace) min/mi")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        
                                        
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                }
                                .padding(16)
                                
                            }
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            .padding(.vertical, 4)
                            
                        }
                        .sheet(isPresented: $isShowingPaceInformationSheet ) {
                            ScrollView {
                                
                                VStack(alignment: .leading, spacing: 32) {
                                    
                                    VStack(alignment: .leading) {
                                        Text("Pace Details")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .bold()
                                        
                                        Text("Your average pace describes the time it takes to travel a certain unit of distance. Solo calculates this as soon as you complete a run. This differs from your active pace, which pro users can view down below as a graph for more details. If your graph is flat, it could mean your movement wasn't active enough."
                                        )
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .font(.subheadline)
                                    }
                                    .padding(.top, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .center) {
                                            
                                            Text("Your pace chart")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                                .bold()
                                            
                                            
                                            if subscriptionManager.hasSubscriptionExpired() {
                                                Text("Pro")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(RoundedRectangle(cornerRadius: 8).fill(BLUE))
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Data is displayed as seconds per meter")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .font(.subheadline)
                                    }
                                    .padding(.bottom, 16)
                                    
                                    
                                    VStack(alignment: .leading) {
                                        
                                        if let paceArray = runData.paceArray, !paceArray.isEmpty  {
                                            let sortedPaceArray = paceArray.sorted { $0.timeSeconds < $1.timeSeconds }
                                            
                                            let slowestPace = sortedPaceArray.max { item1, item2 in
                                                return item2.pace > item1.pace
                                            }?.pace ?? 0
                                            
                                            
                                            // Change the size of the rolling window
                                            let visibleDomain: Int = {
                                                let minutes = secondsToMinutes(seconds: runData.elapsedTime)
                                                
                                                switch minutes {
                                                case 0...10:
                                                    return 60       // 1 minute
                                                case 11...30:
                                                    return 60 * 2   // 2 minutes
                                                default:
                                                    return 60 * 5   // 5 minutes
                                                }
                                            }()
                                        
                                            // stide in seconds
                                            let stride: Float = {
                                                let minutes = secondsToMinutes(seconds: runData.elapsedTime)
                                                
                                                switch minutes {
                                                case 0...30:
                                                    return 30   // 30 seconds
                                                default:
                                                    return 60   // 60 seconds
                                                }
                                            }()
                                            
                                            Chart {
                                                ForEach(sortedPaceArray) { paceData in
                                                    LineMark(
                                                        x: .value("Time", paceData.timeSeconds),
                                                        y: .value("Pace", paceData.pace)
                                                    )
                                                    .foregroundStyle(Color.green)
                                                }
                                            }
                                            .frame(height: 280)
                                            .chartXSelection(value: $selectedTime.animation(.spring))
                                            .chartXAxis {
                                                AxisMarks(values: .stride(by: stride)) { value in
                                                    if let seconds = value.as(Int.self) {
                                                        AxisValueLabel {
                                                            // Presents the time as 1:20 or 01:20:30
                                                            let hour = seconds / 3600
                                                            if hour > 0 {
                                                                let formattedDuration = Duration.seconds(seconds).formatted(
                                                                    .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
                                                                )
                                                                Text("\(formattedDuration)")
                                                            } else {
                                                                let formattedDuration = Duration.seconds(seconds).formatted(
                                                                    .time(pattern: .minuteSecond)
                                                                )
                                                                Text("\(formattedDuration)")
                                                            }
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            .chartYScale(domain: 0...(slowestPace + 1))
                                            .chartScrollableAxes(.horizontal)
                                            .chartXVisibleDomain(length: visibleDomain)
                                            .chartXSelection(value: $selectedTime.animation(.spring))
                                            
                                        } else {
                                            VStack(alignment: .center, spacing: 8) {
                                                Image(systemName: "chart.bar.xaxis")
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                
                                                Text("No pace data was found")
                                                    .font(.subheadline)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 280)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                                        }
                                    }
                                    .blur(radius: subscriptionManager.hasSubscriptionExpired() ? 10 : 0)
                                    .disabled(subscriptionManager.hasSubscriptionExpired())
                                    
                                    Spacer()
                                }
                            }
                            .scrollIndicators(.hidden)
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .presentationDetents(paceInformationSheetDetents)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .presentationBackground(.black)
                            .presentationDragIndicator(.visible)
                        }
                        
                        Spacer().frame(height: 48)
                        
                        // Route data section
                        VStack(alignment: .leading) {
                         
                            Text("Route")
                                .font(.title3)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .fontWeight(.semibold)
                                .padding(.bottom, 16)
                            
                            
                            // Route start and end timeline
                            VStack {
                                VStack {
                                    HStack(alignment: .top, spacing: 8) {
                                        
                                        if let startPlacemark = runData.startPlacemark {
                                            Image(systemName: "location.circle.fill")
                                                .foregroundStyle(.white, BLUE)
                                            
                                            
                                            VStack(alignment: .leading) {
                                                Text(startPlacemark.name)
                                                    .foregroundStyle(.white)
                                                    .font(.subheadline)
                                                
                                                Text("\(startPlacemark.locality)")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                        }
                                    }
                                    
                                    
                                    Divider()
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        
                                        if let endPlacemark = runData.endPlacemark {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(.white, endPlacemark.isCustomLocation ?  .yellow : .red )
                                            
                                            VStack(alignment: .leading) {
                                                Text(endPlacemark.name)
                                                    .foregroundStyle(.white)
                                                    .font(.subheadline)
                                                
                                                Text("\(endPlacemark.thoroughfare), \(endPlacemark.locality)")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(16)
                            }
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            
                            if routeTabItems.isEmpty  {
                                Spacer().frame(height: 16)
                                
                                VStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .font(.title)
                                    
                                    Text("No route image was found")
                                        .font(.subheadline)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 360)
                                .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            }
                            else {
                                TabView {
                                    
                                    ForEach(routeTabItems, id: \.self) { item in
                                        
                                        ZStack(alignment: .topLeading) {
                                            
                                            Image(uiImage: (item == "route" ? routeImageData : breadCrumbImageData)!)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 360)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            VStack(alignment: .leading, spacing: 16) {
                                                
                                                Text((item == "route") ? "route" : "breadcrumb")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(item == "route" ? .white : TEXT_LIGHT_GREEN)
                                                    .padding(8)
                                                    .background(RoundedRectangle(cornerRadius: 8).fill((item == "route") ? BLUE : DARK_GREEN).opacity(0.8))
                                            
                                                
                                                ShareLink(
                                                    item: (item == "route" ? exportedRouteImage() : exportedBreadCrumbImage()),
                                                    preview: SharePreview("\(convertDateToDateTime(date: runData.startTime)) Run", image: (item == "route" ? exportedRouteImage() : exportedBreadCrumbImage())))
                                                {
                                                    
                                                    Circle()
                                                        .frame(width: 36, height: 36)
                                                        .foregroundStyle(.ultraThinMaterial)
                                                        .opacity(0.8)
                                                        .overlay(
                                                            Image(systemName: "square.and.arrow.up")
                                                                .foregroundStyle(.white)
                                                                .fontWeight(.bold)
                                                                .offset(y: -2)
                                                        )
                                                        
                                                }
                                            }
                                            .padding(16)
                                        }
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: (routeTabItems.count > 1) ? .always : .never))
                                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                                .frame(height: 450)
                                .offset(y:-16)
                                .frame(maxWidth: .infinity)
                                
                            }
                            
                        }
                        
                        Spacer().frame(height: 32)
                        
                        // Notes section
                        VStack(alignment: .leading) {
                            
                            Text("Notes")
                                .font(.title3)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .fontWeight(.semibold)
                            
                            TextField(
                                "",
                                text: Binding( get: { runData.notes }, set: { newValue in runData.notes = newValue }),
                                prompt: Text("Write a note...").foregroundColor(.white),
                                axis: .vertical
                            )
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(DARK_GREY)
                            .cornerRadius(12)
                            .focused($notesIsFocused)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer().frame(height: 100)
                        
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .toolbarBackground(.clear, for: .navigationBar)
                    .toolbar {
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showRunDetailView = false
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(2)
                            }
                        }
                        
                        ToolbarItem(placement: .principal) {
                            VStack(alignment: .center) {
                                
                                Text(runData.startTime.formatted(
                                    .dateTime
                                        .day()
                                        .month(.abbreviated)
                                        .year()
                                ))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            if notesIsFocused {
                                Button("Done") {
                                    notesIsFocused = false
                                }
                                .foregroundStyle(.white)
                            } else {
                                
                                Menu {
                                    Button {
                                        showDeleteDialog = true
                                    } label: {
                                        
                                        Button("Delete this run") {
                                            showDeleteDialog = true
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .padding(2)
                                }
                                .alert("Are you sure you want to delete this run?", isPresented: $showDeleteDialog) {
                                    Button("Yes", role: .destructive){
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            modelContext.delete(runData)
                                        }
                                        
                                        // Dimiss this view
                                        showRunDetailView = false
                                        //dismiss()
                                        
                                    }
                                    Button("Cancel", role: .cancel){}
                                }
                            }
                        }
                    }
                    
                }
                
                // Showing the expanded route image view
                else {
                    
                    VStack {
                        
                        HStack {
                            Spacer()
                            
                            // Custom dismiss button
                            Button {
                                withAnimation {
                                    isShowingExpanded = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                                    .font(.title)
                            }
                        }
                        .padding(16)
                        
                        
                        VStack {
                            Spacer()
                            
                            if let routeImage = routeImageData {
                                Image(uiImage: routeImage)
                                    .resizable()
                                    .scaledToFit()
                                    .matchedGeometryEffect(id: "image", in: namespace)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                if routeImageData != nil {
                    routeTabItems.append("route")
                }
                if breadCrumbImageData != nil {
                    routeTabItems.append("breadcrumb")
                }
            }
            
        }
        .background(.black)
        .preferredColorScheme(.dark)
    }
}




