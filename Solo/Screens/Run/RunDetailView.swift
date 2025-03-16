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
    var image: UIImage
    var runData: Run
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
            
            VStack(alignment: .leading, spacing: 8) {
                
                VStack(alignment: .leading) {
                    Text(runData.endPlacemark!.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("\(convertDateToTime(date: runData.startTime)) - \(convertDateToTime(date: runData.endTime))")
                        .font(.caption)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                }
                
                HStack(alignment: .center, spacing: 8){
                    
                    Text("\(runData.steps) steps")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(DARK_GREY))
                        .foregroundColor(.white)
                    
                    Text(String(format:"%.2f mi", runData.distanceTraveled / 1609.344))
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(DARK_GREY))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .padding(8)
        }
        .frame(width: 200)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black))
    }
}



/**
 Displays a user's previous run session with statistics like time, steps, distance, and average pace.
 Users also have the ability to add notes for the run.
 */
struct RunDetailView: View {
    
    var runData: Run!
    //var onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isShowingExpanded: Bool = false
    @Namespace var namespace
    
    @FocusState var notesIsFocused: Bool
    
    @State private var paceInformationSheetDetents: Set<PresentationDetent> = [.fraction(0.35), .large]
    @State private var isShowingPaceInformationSheet: Bool = false
    @State private var selectedTime: Int?
    
    @State private var showDeleteDialog: Bool = false

    let numberOfPaceMarks: Int = 5
    
    var imageData: UIImage? {
        guard let imageData = runData?.routeImage else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    var imageForShare: Image? {
        guard let uiImage = imageData else {
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
    
    @MainActor func exportedImage() -> Image {
        let renderer = ImageRenderer(content: ExportableImageCard(image: imageData!, runData: runData))
        renderer.scale = UIScreen.main.scale
        return Image(uiImage: renderer.uiImage!.withCornerRadius(12).withBackground(color: .clear))

    }
 
    var body: some View {
        
        ZStack {
            if !isShowingExpanded {
                NavigationStack {
                    ScrollView(showsIndicators: false) {
                        
                        // Run statistics section
                        VStack(alignment: .leading) {
                            
                            HStack(alignment: .center) {
                                
//                                Text("Statistics")
//                                    .font(.title3)
//                                    .foregroundStyle(TEXT_LIGHT_GREY)
//                                    .fontWeight(.semibold)
                               
                                
                                CapsuleView(background: DARK_GREY, iconName: "timer", iconColor: .white, text: formattedElapsedTime(from: runData.startTime, to: runData.endTime) )
                                
                                Spacer()
                                
                                Text("\(convertDateToTime(date: runData.startTime)) - \(convertDateToTime(date: runData.endTime))")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                
                            }
                            .padding(.top, 24)
                                    
                            
                            
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
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("What is my average pace?")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .bold()
                                        .padding(.top, 16)
                                    
                                    Text("Your average pace describes the time it takes to travel a given distance. Solo Running calculates this as soon as you complete a run. Pro users can also view their active pace over time down below for more details."
                                    )
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .font(.subheadline)
                                    
                                    
                                    Spacer().frame(height: 32)
                                    
                                   
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

                                        
                                        if let paceArray = runData.paceArray, !paceArray.isEmpty && !paceArray.allPaceAreZero {
                                            
                                            let sortedPaceArray = paceArray.sorted { $0.timeSeconds < $1.timeSeconds }

                                            let slowestPace = sortedPaceArray.max { item1, item2 in
                                                return item2.pace > item1.pace
                                            }?.pace ?? 0
                                                                                        
                                            
                                            let visibleDomain: Int = {
                                                let minutes = secondsToMinutes(seconds: runData.elapsedTime)

                                                switch minutes {
                                                case 0...10:
                                                    return 90       // 1 minute
                                                case 11...30:
                                                    return 60 * 5   // 5 minutes
                                                case 31...60:
                                                    return 60 * 10  // 10 minutes
                                                default:
                                                    return 60 * 20  // 20 minutes
                                                }
                                            }()
                                            
                                            Chart {
                                                /*
                                                if let pace = selectedPaceForTime {
                                                    RuleMark(x: .value("Selected Time", pace.timeSeconds))
                                                        .foregroundStyle(.secondary.opacity(0.3))
                                                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                            VStack(alignment: .leading) {
                                                                
                                                                // Presents the time as 1:20 or 01:20:30
                                                                let seconds = pace.timeSeconds
                                                                let hour = pace.timeSeconds / 3600
                                                                
                                                                if hour > 0 {
                                                                    let formattedDuration = Duration.seconds(seconds).formatted(
                                                                        .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
                                                                    )
                                                                    Text("\(formattedDuration)")
                                                                        .font(.subheadline)
                                                                        .bold()
                                                                } else {
                                                                    let formattedDuration = Duration.seconds(seconds).formatted(
                                                                        .time(pattern: .minuteSecond)
                                                                    )
                                                                    Text("\(formattedDuration)")
                                                                        .font(.subheadline)
                                                                        .bold()
                                                                }
                                                                                                                                
                                                                Text("\(pace.pace) s/m")
                                                                    .font(.title3)
                                                                    .bold()
                                                                                                                           
                                                            }
                                                            .padding(8)
                                                            .frame(width: 154, alignment: .leading)
                                                            .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                                        }
                                                }
                                                */
                                                    
                                                ForEach(sortedPaceArray) { paceData in
                                                    LineMark(
                                                        x: .value("Time", paceData.timeSeconds),
                                                        y: .value("Pace", paceData.pace)
                                                    )
                                                    //.interpolationMethod(.catmullRom)s
                                                    .foregroundStyle(Color.green)
                                                    
                                                    AreaMark(
                                                        x: .value("Day", paceData.timeSeconds),
                                                        y: .value("Pace", paceData.pace)
                                                    )
                                                    //.interpolationMethod(.catmullRom)
                                                    .foregroundStyle(GREEN_GRADIENT)
                                                }
                                            }
                                            .frame(height: 280)
                                            .chartXSelection(value: $selectedTime.animation(.spring))
                                            .chartXAxis {
                                                // Add marks every 30 seconds
                                                AxisMarks(values: .stride(by: 30)) { value in
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
                        VStack(spacing: 16) {
                            
                            VStack(alignment: .leading) {
                                
                                Text("Route")
                                    .font(.title3)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .fontWeight(.semibold)
                                
                                
                                Image(uiImage: imageData!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 340)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .matchedGeometryEffect(id: "image", in: namespace)
                                    .onTapGesture {
                                        withAnimation  {
                                            isShowingExpanded = true
                                        }
                                    }
                                
                            }
                            .frame(maxWidth: .infinity)
                            
                            
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
                            
                            
                            
                            // Share image button
                            Button {
                            } label: {
                                ShareLink(item: exportedImage(), preview: SharePreview("\(convertDateToDateTime(date: runData.startTime)) Run", image: exportedImage())) {
                                    HStack {
                                        Text("Share Route Photo")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(BLUE)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 48)
                        
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
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white, DARK_GREY) // color the dots white and underlying circle grey
                                        .padding(2)
                                }
                                .alert("Are you sure you want to delete this run?", isPresented: $showDeleteDialog) {
                                    Button("Yes", role: .destructive){
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            modelContext.delete(runData)
                                        }
                                    
                                        // Dimiss this view
                                        dismiss()

                                    }
                                    Button("Cancel", role: .cancel){}
                                }
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
                        
                        Image(uiImage: imageData!)
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: "image", in: namespace)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}




