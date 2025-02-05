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
    @Namespace var bottomID
    
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
                
                VStack(alignment: .leading) {
                    
                    Image(uiImage: imageData!)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                    
                    
                    HStack(alignment: .center) {
                        
                        Text("Details")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        CapsuleView(background: LIGHT_GREY, iconName: "timer", iconColor: .white, text: formattedElapsedTime(from: runData.startTime, to: runData.endTime) )
                        
                        // Share image button
                        ZStack(alignment: .center) {
                            Circle().fill(LIGHT_GREY).frame(width: 36, height: 36)
                            
                            ShareLink(item: imageForShare!, preview: SharePreview("Route Image", image: imageForShare!))
                                .labelStyle(.iconOnly)
                                .font(.subheadline)
                                .offset(y: -2)
                        }
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    
                    VStack(alignment: .leading) {
                        // Route start and end timeline
                        VStack {
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                                    .overlay(alignment: .top) {
                                        Rectangle()
                                            .fill(.white.opacity(0.5))
                                            .frame(width: 2, height: 50)
                                    }
                                
                                if let startPlacemark = runData.startPlacemark {
                                    VStack(alignment: .leading) {
                                        Text(startPlacemark.name)
                                            .foregroundStyle(.white)
                                            .font(.subheadline)
                                        
                                        Text("\(startPlacemark.locality)")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    .offset(y: -8)
                                }
                                Spacer()
                            }
                            .frame(height: 40)
                            
                            
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                                
                                if let endPlacemark = runData.endPlacemark {
                                    VStack(alignment: .leading) {
                                        Text(endPlacemark.name)
                                            .foregroundStyle(.white)
                                            .font(.subheadline)
                                        
                                        Text("\(endPlacemark.thoroughfare), \(endPlacemark.locality)")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    .offset(y: -4)
                                }
                                Spacer()
                            }
                            .frame(height: 30)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    .padding(.horizontal, 16)
                 
                    
                    
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

                    
                    VStack {
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
                    .padding(.horizontal, 16)
                    
                    Spacer().frame(height: 100)
                    
                }
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
}

