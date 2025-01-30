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
 A custom header with an image and run statistics that sits at the top of a screen. When the user scrolls the page, the image
 should experience a delayed downward shift to bring the image into better view.
 */
struct ParallaxHeader<Content: View> : View {
    var run: Run!
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let fadeOutOpacity = max(0, 1 - (((offset - 20) * 0.2) / 100))
            
            ZStack {
                content()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .offset(y: -offset * 0.8)
    
                HStack {
                    VStack(alignment: .leading) {
                        Spacer().frame(height: 72)
                        
                        Text("\(convertDateToString(date: run!.startTime)) - \(convertDateToString(date: run!.endTime))")
                            .font(.subheadline)
                            .foregroundStyle(run.isDarkMode ? .white : .black)
                        
                        Text("Run Summary")
                            .fontWeight(.bold)
                            .font(.largeTitle)
                            .foregroundStyle(run.isDarkMode ? .white : .black)
                        
                        Spacer().frame(height: 12)
                        
                        CapsuleView(
                            iconBackground: nil,
                            iconName: "timer",
                            iconColor: TEXT_LIGHT_GREEN,
                            text: timeDifference(from: run!.startTime, to: run!.endTime)
                        )
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .opacity(fadeOutOpacity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }
            .frame(height: 280)
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        }
    }
}


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
            ScrollViewReader { proxy in
                
                GeometryReader { geometry in
                    let fadeInOpacity = min(1, max(0, (scrollOffset - 200) / 200))
                    
                    Color.clear
                        .onAppear {
                            scrollOffset = geometry.frame(in: .global).minY
                        }
                        .onChange(of: geometry.frame(in: .global).minY) { old, new in
                            scrollOffset = new
                        }
                    
                    ScrollView(showsIndicators: false) {
                        if imageData != nil {
                            ParallaxHeader(run: runData!) {
                                Image(uiImage: imageData!)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(height: 200)
                        }
                        
                        VStack(alignment: .leading) {
                            HStack() {
                                Text("Details")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                ShareLink(item: imageForShare!, preview: SharePreview("Route Image", image: imageForShare!))
                                    .labelStyle(.iconOnly)
                                    .background(Circle().fill(DARK_GREY).padding(6))
                            }
                            
                            // Route start and end timeline
                            VStack(spacing: 16) {
                                HStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 12, height: 12)
                                    
                                    if let startPlacemark = runData.startPlacemark {
                                        Text(startPlacemark.name)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                    Spacer()
                                }
                                .overlay(alignment: .topLeading){
                                    Rectangle()
                                        .fill(.white)
                                        .frame(width: 1.5, height: 32)
                                        .offset(y: 16)
                                        .padding(.leading, 5.5)
                                }
                                
                                HStack(alignment: .top) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 12, height: 12)
                                    
                                    if let endPlacemark = runData.endPlacemark {
                                        Text(endPlacemark.name)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .offset(y: -4)
                                    }
                                    Spacer()
                                }
                            }
                            
                            VStack(spacing: 16) {
                                Spacer().frame(height: 32)
                                
                                HStack {
                                    Text("Distance (meters)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text((String(format: "%.2f", runData!.distanceTraveled)))
                                        .foregroundStyle(.white)
                                }
                                .padding(20)
                                .background(LIGHT_GREY)
                                .cornerRadius(12)
                                
                                HStack {
                                    Text("Total steps")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(runData!.steps)")
                                        .foregroundStyle(.white)
                                    
                                }
                                .padding(20)
                                .background(LIGHT_GREY)
                                .cornerRadius(12)
                                
                                HStack {
                                    Text("Avg Pace (min/mile)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(runData!.avgPace)")
                                        .foregroundStyle(.white)
                                    
                                }
                                .padding(20)
                                .background(LIGHT_GREY)
                                .cornerRadius(12)
                                
                                Spacer().frame(height: 32)
                            }
                            
                            
                            VStack(alignment: .leading) {
                                Text("Notes")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                
                                TextField(
                                    "",
                                    text: Binding( get: { runData.notes }, set: { newValue in runData.notes = newValue }),
                                    prompt: Text("Write something...").foregroundColor(.white),
                                    axis: .vertical
                                )
                                .foregroundStyle(.white)
                                .padding(20)
                                .background(LIGHT_GREY)
                                .cornerRadius(12)
                                .focused($notesIsFocused)
                                .onChange(of: notesIsFocused) { old, new in
                                    if new {
                                        print("scrolling to bottom")
                                        proxy.scrollTo(bottomID)
                                    }
                                }
                            }
                            
                            Spacer().frame(height: 200)
                            VStack {}.id(bottomID)
                        }
                        .padding(.top)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(.black)
                    }
                    .defaultScrollAnchor(.top)
                    .background(.black)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Color
                                .clear
                                .opacity(fadeInOpacity)
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
}

