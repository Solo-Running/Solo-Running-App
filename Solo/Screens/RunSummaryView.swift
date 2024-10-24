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
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let isScrolled = offset > 0
            content()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .offset(y: -offset * 0.8)

        }
        .frame(height: 340)
    }
}
struct RunSummaryView: View {
    
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    @Environment(\.modelContext) private var modelContext
    @Binding var showRunView: Bool

    @Query private var runs: [Run]
    var savedRun: Run? {runs.last}
        
    func convertDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"  // 'h' is for hour in 12-hour format, 'a' is for AM/PM

        let timeString = formatter.string(from: date)
        return timeString
    }
    
    
    var body: some View {
        
        
        ScrollView(showsIndicators: false) {
            
            
            if let imageData = savedRun?.routeImage, let uiImage = UIImage(data: imageData) {
                ParallaxHeader {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                    
                    
                }
                .frame(height: 340)
            }
                
                                
            VStack(alignment: .leading){
                
                Text("Run Summary")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                    .padding(.bottom, 2)
                
                Text("Today \(convertDateToString(date: savedRun!.startTime)) - \(convertDateToString(date: savedRun!.endTime))")
                    .foregroundStyle(TEXT_LIGHT_GREY)
                    .font(.subheadline)
                
                Spacer().frame(height: 24)

                
                HStack {
                    
                    
                }
                .padding()
                .frame(height: 96)
                .frame(maxWidth: .infinity) // Fills the entire width
                .background(LIGHT_GREY)
                .cornerRadius(12) // Rounds the corners
                

                Spacer().frame(height: 24)
                
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
