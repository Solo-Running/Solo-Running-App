//
//  DashboardView.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI
import SwiftData
import Charts


struct StepsPerDay: Identifiable {
    var id = UUID()
    var day: String
    var steps: Int
}


struct DashboardView: View {
    
    @Environment(\.modelContext) var modelContext
    
    // Get the runs for the past week
    @State var stepsPerDay: [String: Int] = [:]
    
    @State var totalStepsInWeek: Int = 0
    @State var averageStepsInWeek: Int = 0
    @State var stepsPercentageChange: Int = 0
    
    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= weekAgoDate
    }, sort: \Run.postedDate) private var weeklyRuns: [Run]
        

    // Fetch the user data
    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}
   
    
//    private var dayFormatter: DateFormatter {
//          let formatter = DateFormatter()
//          formatter.dateFormat = "E"
//          return formatter
//    }
//    
    
    private static var weekAgoDate: Date {
        return Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    }
    
    // Creates an array of dates spanning the past week
    let days: [String] = {
        var dates: [String] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        var weekDay = weekAgoDate
        
        while weekDay <= Date() {
            let day = dateFormatter.string(from: weekDay)
            dates.append(day)
            weekDay = calendar.date(byAdding: .day,  value: 1, to: weekDay)!
        }
        
        return dates
    }()
    
    
    
    func generateStepsPerDay() {
        
        let calendar = Calendar.current

        // Create temporary dictionary for storing calculations
        var stepsDictionary: [String: Int] = Dictionary(uniqueKeysWithValues: days.map { ($0, 0) })
        
        // Track total steps and change in steps since yesterday
        var totalSteps = 0
        var todaySteps = 0
        var yesterdaySteps = 0
        
        let stepsPerDateObject = Dictionary(grouping: weeklyRuns, by: {Calendar.current.startOfDay(for: $0.postedDate)})
            .mapValues {runs in runs.reduce(0) {$0 + $1.steps}}
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        // Set the steps for each abbreviated day in the dictionary
        for (date, steps) in stepsPerDateObject {
            let dayAbbreviation = dateFormatter.string(from: date)
            stepsDictionary[dayAbbreviation] = steps
            totalSteps += steps
            
            if date == Date() {
                todaySteps = steps
            }
            
            if date == calendar.date(byAdding: .day,  value: -1, to: date) {
                yesterdaySteps = steps
            }
        }
        
        self.stepsPerDay = stepsDictionary
        
        // Update the total steps state
        self.totalStepsInWeek = totalSteps
        
        // Calculate the average steps for this week
        self.averageStepsInWeek = Int(ceil(Double(totalSteps) / 7))
        
        // Calculate the percentage increase from yesterday's steps
        if yesterdaySteps > 0 {
            self.stepsPercentageChange =  Int(ceil(Double(todaySteps - yesterdaySteps) / Double(yesterdaySteps)))
        } else {
            self.stepsPercentageChange = 100
        }
    }

    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                
                // Container for holding run statistics
                VStack(alignment: .leading){
                    
                    Spacer().frame(height: 16)
                    
                    VStack(alignment: .leading) {
                        
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: -2) {
                                Text("Steps last 7 days")
                                    .font(Font.custom("Koulen-Regular", size: 20))
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                                
                                Text("You ran a total of \(totalStepsInWeek) steps this week")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                            
                            Spacer()
                            
                            Text("\(stepsPercentageChange)%")
                                .foregroundStyle(LIGHT_GREEN)
                                .fontWeight(.semibold)
                            
                        }
                        .padding(.bottom, 8)
                        
                        if !self.stepsPerDay.isEmpty {
                            
                            Chart(days, id: \.self) { day in
                                
                                // Display the average steps as a horizontal dashed line
                                RuleMark(y: .value("Average Steps", self.averageStepsInWeek)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2,2]))
                                    .annotation(position: .top, alignment: .leading) {
                                        Text("Average: \(self.averageStepsInWeek)")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .background(
                                                RoundedRectangle(cornerRadius: 2).fill(LIGHT_GREY)
                                            )
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                    }
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                
                                // Show bars for steps per day if nonzero, otherwise display a default bar
                                if self.stepsPerDay[day]! > 0 {
                                    BarMark (
                                        x: .value("Day", day),
                                        y: .value("Steps", self.stepsPerDay[day]!)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(NEON)
                                    .annotation {
                                        if day == days.last {
                                            Text("\(self.stepsPerDay[day]!)")
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                } else {
                                    BarMark (
                                        x: .value("Day", day),
                                        y: .value("Steps", 10)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(DARK_GREY)
                                }
                                
                            }
                            .chartYAxis(.hidden)
                            .chartXAxis {
                                AxisMarks() {
                                    AxisValueLabel()
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
                                
                            }
                        }
                        
                    }
                    .padding()
                    .background(LIGHT_GREY)
                    .cornerRadius(16)
                    .frame(height: 200)
                    
                    
                    
                    
                    HStack {
                        
                    }
                    .padding(.bottom, 24)
                    
                    Spacer()
                    
                    
                }
                .padding(.horizontal, 16)
                .onAppear {
                    print("View Appeared. fetching new steps")
                    generateStepsPerDay()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        
                        Group{
                            // Safely unwrap the user's profile picture and check if it's not empty
                            if let profileData = user?.profilePicture, !profileData.isEmpty, let profileImage = UIImage(data: profileData) {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill) // Ensure the image fills the frame
                                    .clipped()
                            } else {
                                // If profile picture is empty, show a default person icon
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(LIGHT_GREY)
                        .clipShape(Circle())
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                
                VStack(alignment: .leading) {
                }

            }
            .background(.black)

        }
    }
}





struct RunCard: View {
    var body: some View {
        
    }
}
