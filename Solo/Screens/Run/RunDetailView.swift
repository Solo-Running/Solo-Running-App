//
//  RunDetailView.swift
//  Solo
//
//  Created by William Kim on 10/28/24.
//

import Foundation
import SwiftUI
import SwiftData


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
    
    @State private var isShowingExpanded: Bool = false
    @Namespace var namespace
    @FocusState var notesIsFocused: Bool
    
    
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
                        VStack {
                            HStack(alignment: .center) {
                                
                                Text("Statistics")
                                    .font(.title3)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                CapsuleView(background: DARK_GREY, iconName: "timer", iconColor: .white, text: formattedElapsedTime(from: runData.startTime, to: runData.endTime) )
                            }
                            .padding(.top, 24)
                            
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
                                        Text("Average Pace")
                                            .font(.subheadline)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                        
                                        Text("\(runData!.avgPace) min/mi")
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
                
//                .toolbar(.hidden, for: .navigationBar)
//                .toolbar(.hidden, for: .tabBar)
//                .safeAreaInset(edge: .top, content: { Color.clear.frame(height: 44) })
//                .safeAreaInset(edge: .bottom, content: { Color.clear.frame(height: 64) })
            }
        }
    }
}




/*
 VStack(spacing: 24) {
 
 VStack(alignment: .leading) {
 Text("Duration")
 .font(.subheadline)
 .foregroundStyle(LIGHT_GREEN)
 
 Text("\(convertDateToTime(date: runData.startTime)) - \(convertDateToTime(date: runData.endTime))")
 .foregroundStyle(.white)
 .font(.subheadline)
 .fontWeight(.semibold)
 }
 .frame(maxWidth: .infinity, alignment: .leading)
 .padding(.horizontal, 16)
 .padding(.top, 16)
 
 VStack(alignment: .leading) {
 Text("Average Pace")
 .font(.subheadline)
 .foregroundStyle(LIGHT_GREEN)
 
 Text("\(runData!.avgPace) min/mi")
 .foregroundStyle(.white)
 .font(.subheadline)
 .fontWeight(.semibold)
 }
 .frame(maxWidth: .infinity, alignment: .leading)
 .padding(.horizontal, 16)
 
 VStack(alignment: .leading) {
 Text("Distance Traveled")
 .font(.subheadline)
 .foregroundStyle(LIGHT_GREEN)
 
 Text("\(formattedSteps(runData!.steps)) steps")
 .foregroundStyle(.white)
 .font(.subheadline)
 .fontWeight(.semibold)
 }
 .frame(maxWidth: .infinity, alignment: .leading)
 .padding(.horizontal, 16)
 .padding(.bottom, 16)
 
 
 }
 .frame(maxWidth: .infinity)
 .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
 .padding(.vertical, 8)
 .padding(.horizontal, 16)
 
 
 */
