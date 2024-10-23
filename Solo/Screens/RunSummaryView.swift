//
//  RunSummaryView.swift
//  Solo
//
//  Created by William Kim on 10/19/24.
//

import Foundation
import SwiftUI
import SwiftData

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
        
        NavigationStack {
            // hide scrollbar
            ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        VStack(alignment: .leading) {
                            if let imageData = savedRun?.routeImage, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            HStack(alignment: .center) {
                                ZStack {
                                    Circle()
                                        .background(.white)
                                        .frame(width: 20, height: 20)
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.red)
                                }
                                .padding([.top, .trailing], 4)
                                
                                Text(savedRun!.endLocation.name!)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        
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
                        
                   
                                        
                    
                        Button  {
                            showRunView = false
                        } label: {
                            HStack {
                                Text("Back to home").foregroundStyle(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.green)
                            .cornerRadius(12)
                            
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        
                       
                    
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    
                    ToolbarItem(placement: .topBarLeading) {
                        VStack(alignment: .leading){
                            Spacer().frame(height: 8)
                            Text("Run Summary")
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            
                            Text("Today \(convertDateToString(date: savedRun!.startTime)) - \(convertDateToString(date: savedRun!.endTime))")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                            
                            Spacer().frame(height: 8)

                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
