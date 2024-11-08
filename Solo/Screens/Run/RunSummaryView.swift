//
//  RunSummaryView.swift
//  Solo
//
//  Created by William Kim on 10/19/24.
//

import Foundation
import SwiftUI
import SwiftData


struct ParallaxHeader<Content: View> : View {
    var run: Run!
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let fadeOutOpacity = max(0, 1 - (((offset - 20) * 0.4) / 100))
            
            ZStack {
                content()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .offset(y: -offset * 0.8)
//                    .brightness(max(-0.5, min(0.3, offset * 0.01)))
                    
    
                HStack {
                    VStack(alignment: .leading) {
                        Spacer().frame(height: 160)
                        
                        Text("\(convertDateToString(date: run!.startTime)) - \(convertDateToString(date: run!.endTime))")
                            .foregroundStyle(.white)
                            .font(.subheadline)
                        
                        Text("Run Summary")
                            .fontWeight(.bold)
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                        
                        Spacer().frame(height: 12)
                        
                        CapsuleView(
                            capsuleBackground: LIGHT_GREEN,
                            iconName: "timer",
                            iconColor: Color.white,
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
            .frame(height: 300)
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        }
    }
}



struct RunSummaryView: View {
    
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    @Environment(\.modelContext) private var modelContext
    @Binding var showRunView: Bool

    @Query private var runs: [Run]
    var savedRun: Run? {runs.last}
        
    
    var body: some View {
        
        
        ScrollView(showsIndicators: false) {
            
            if let imageData = savedRun?.routeImage, let uiImage = UIImage(data: imageData) {
                ParallaxHeader(run: savedRun!) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .frame(height: 300)
            }
                
                                
            VStack(alignment: .leading) {
                
                HStack {
                    Text("Details")
                        .foregroundStyle(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 8)
                    
                    Spacer()
                }
                .padding(.bottom, 16)
              
                // Route start and end timeline
                VStack(spacing: 16) {
                    
                    HStack {
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                        
                        
                        Text((savedRun?.startPlacemark.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                    .overlay(alignment: .topLeading){
                        Rectangle()
                            .fill(.white)
                            .frame(width: 1.5, height: 32)
                            .offset(y: 16)
                            .padding(.leading, 5.5)
                    }
                    
                    HStack {
                    
                        Circle()
                          .fill(.white)
                          .frame(width: 12, height: 12)
                        
                        Text((savedRun?.endPlacemark.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                    
                }

                Spacer().frame(height: 48)
  
                // Run statistics
                HStack {
                    Text("Distance (Meters)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text((String(format: "%.2f", savedRun!.distanceTraveled)))
                        .foregroundStyle(.white)

                }
                .padding()
                .background(LIGHT_GREY)
                .cornerRadius(12)
                
                HStack {
                    Text("Average Speed (MPH)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text((String(format: "%.2f", savedRun?.avgSpeed ?? 0)))
                        .foregroundStyle(.white)

                }
                .padding()
                .background(LIGHT_GREY)
                .cornerRadius(12)

                HStack {
                    Text("Avg Pace (Min/Mile)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text("\(savedRun!.avgPace)")
                        .foregroundStyle(.white)

                }
                .padding()
                .background(LIGHT_GREY)
                .cornerRadius(12)
                
                Spacer().frame(height: 48)
            
                Button  {
                    showRunView = false
                } label: {
                    HStack {
                        Text("Home").foregroundStyle(TEXT_DARK_NEON)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NEON)
                    .cornerRadius(12)
                    
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(.black)
            

        }
        .background(.black)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.clear, for: .navigationBar) // Make navigation bar background transparent
//        .ignoresSafeArea()
    }
    
}


/*
 
 
 HStack {
     Text("Distance")
         .font(.title3)
         .foregroundStyle(.white)
         .fontWeight(.semibold)
     
     Spacer()
     
     Text((String(format: "%.2f meters", savedRun!.distanceTraveled)))

 }
 .padding(.vertical, 8)
 


HStack {
    Text("Duration")
        .font(.title3)
        .foregroundStyle(.white)
        .fontWeight(.semibold)
    
    Spacer()
    
    Text(
        Duration.seconds(savedRun!.elapsedTime).formatted(
            .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
        ))
}
.padding(.vertical, 8)


HStack {
    Text("Average Speed")
        .font(.title3)
        .fontWeight(.semibold)
    
    Spacer()

    Text((String(format: "%.2f", savedRun?.avgSpeed ?? 0)))
}
.padding(.vertical, 8)


HStack {
    Text("Average Pace")
        .font(.title3)
        .fontWeight(.semibold)
    
    Spacer()

    Text("\(savedRun!.avgPace)")
}
.padding(.vertical, 8)
*/


//                    HStack(alignment: .center) {
//                        ZStack {
//                            Circle()
//                                .background(.white)
//                                .frame(width: 20, height: 20)
//
//                            Image(systemName: "mappin.circle.fill")
//                                .font(.title)
//                                .foregroundStyle(.red)
//                        }
//                        .padding([.top, .trailing], 4)
//
//                        Text(savedRun!.endLocation.name!)
//                            .foregroundStyle(TEXT_LIGHT_GREY)
//                    }


/*
 
 
 
 // Swipable carousel of run statistics
 TabView {
     
     VStack(alignment: .center) {
         Text(
             Duration.seconds(savedRun!.elapsedTime).formatted(
                 .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
             ))
         .foregroundStyle(NEON)
         .font(.system(size: 48)).fontWeight(.heavy)
         
         Text("Duration")
             .foregroundStyle(.white)
             .fontWeight(.semibold)
     }
     
     
     VStack(alignment: .center) {
         Text((String(format: "%.2f", savedRun!.distanceTraveled)))
             .foregroundStyle(NEON)
             .font(.system(size: 48)).fontWeight(.heavy)
         
         Text("Distance (meters)")
             .foregroundStyle(.white)
             .fontWeight(.semibold)
     }
     
     
     VStack(alignment: .center) {
         Text((String(format: "%.2f", savedRun?.avgSpeed ?? 0)))
             .foregroundStyle(NEON)
             .font(.system(size: 48)).fontWeight(.heavy)
         
         Text("Avg Speed")
             .foregroundStyle(.white)
             .fontWeight(.semibold)
     }
     
     
     
     VStack(alignment: .center) {
         Text("\(savedRun!.avgPace)")
             .foregroundStyle(NEON)
             .font(.system(size: 48)).fontWeight(.heavy)
         
         Text("Avg Pace")
             .foregroundStyle(.white)
             .fontWeight(.semibold)
     }
     
 }
 .tabViewStyle(PageTabViewStyle())
 .frame(height: 200)
 .frame(maxWidth: .infinity)
 .background(LIGHT_GREY)
 .cornerRadius(24) // Rounds the corners
 
 */
