//
//  RunDetailView.swift
//  Solo
//
//  Created by William Kim on 10/28/24.
//

import Foundation
import SwiftUI
import SwiftData

/**
 Displays a user's previous run session with statistics like time, steps, distance, and average pace.
 It utilizes the ParallaxHeader component to render the route image at the top of the screen.
 Users also have the ability to add notes for the run.
 */
struct RunDetailView: View {
    
    var runData: Run!
    @State private var scrollOffset: CGFloat = 0
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
    
    
    var body: some View {
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
                    .padding(.vertical, 4)
                    
                    
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
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                    
                    // Route start and end timeline
                    VStack {
                        VStack {
                            HStack(alignment: .top, spacing: 8) {
                                
                                if let startPlacemark = runData.startPlacemark {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundStyle(BLUE)
                                    
                                    
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
                                        .foregroundStyle(endPlacemark.isCustomLocation ?  .yellow : .red )
                                    
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
                        
                        ShareLink(item: imageForShare!, preview: SharePreview("Route Image", image: imageForShare!)) {
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
            .padding(.top)
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
