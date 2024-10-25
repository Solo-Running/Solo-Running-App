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
        
    // Formats a Date to friendly format into 1:13am
    func convertDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"  // 'h' is for hour in 12-hour format, 'a' is for AM/PM

        let timeString = formatter.string(from: date)
        return timeString
    }
    
    
    // Formats time difference between start and end times into 1hr 2min
    func timeDifference(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
           
           // Get the difference in hours, minutes, and seconds
           let components = calendar.dateComponents([.hour, .minute, .second], from: startDate, to: endDate)
           
           // Extract the hours, minutes, and seconds
           let hours = components.hour ?? 0
           let minutes = components.minute ?? 0
           let seconds = components.second ?? 0

           // Create the formatted string
           var result = ""
           
           if hours > 0 {
               result += "\(hours)hr "
           }
           
           if minutes > 0 {
               result += "\(minutes)min "
           }
           
           // If the difference is less than 60 seconds, display seconds
           if hours == 0 && minutes == 0 && seconds > 0 {
               result = "\(seconds)sec"
           }

           return result.isEmpty ? "0sec" : result
    }
    
    
    // Converts CMPedometer Pace Units to Minutes/Mile
    func convertPace(secondsPerMeter: Double) -> Double {
        let minutesPerMeter = secondsPerMeter / 60
        let minutesPerMile = minutesPerMeter * 1609.34
        return minutesPerMile
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
                
                                
            VStack(alignment: .leading) {
               
                Text("Today \(convertDateToString(date: savedRun!.startTime)) - \(convertDateToString(date: savedRun!.endTime))")
                    .foregroundStyle(TEXT_LIGHT_GREY)
                    .font(.subheadline)
                
                Text("Run Summary")
                    .fontWeight(.bold)
                    .font(.largeTitle)
    
                Spacer().frame(height: 12)

                CapsuleView(
                    capsuleBackground: LIGHT_GREEN,
                    iconName: "timer",
                    iconColor: Color.white,
                    text: timeDifference(from: savedRun!.startTime, to: savedRun!.endTime)
                )
                
                Spacer().frame(height: 24)

                
                // Route start and end timeline
                VStack(spacing: 16) {
                    HStack {
                        
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .fill(.black)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text((savedRun?.startLocation.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                    .overlay(alignment: .topLeading){
                        Rectangle()
                            .frame(width: 1.5, height: 24)
                            .offset(y: 16)
                            .padding(.leading, 9)
                    }
                    
                    HStack {
                        
                        ZStack {
                            Circle()
                              .fill(.white)
                              .frame(width: 20, height: 20)
                          
                            Circle()
                              .fill(.black)
                              .frame(width: 8, height: 8)
                        }
                        
                        Text((savedRun?.endLocation.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                }

                Spacer().frame(height: 48)
  
                // Run statistics
                HStack {
                    Text("Distance (Meters)")
                        .font(Font.custom("Koulen-Regular", size: 20))
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text((String(format: "%.2f", savedRun!.distanceTraveled)))
                }
                .padding()
                .background(LIGHT_GREY)
                .cornerRadius(12)
                
                HStack {
                    Text("Average Speed (MPH)")
                        .font(Font.custom("Koulen-Regular", size: 20))
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text((String(format: "%.2f", savedRun?.avgSpeed ?? 0)))
                }
                .padding()
                .background(LIGHT_GREY)
                .cornerRadius(12)

                HStack {
                    Text("Avg Pace (Min/Mile)")
                        .font(Font.custom("Koulen-Regular", size: 20))
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text("\(savedRun!.avgPace)")
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
