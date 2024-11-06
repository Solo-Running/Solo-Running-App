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



struct RunStats {
    var steps: Int
    var paceMinutesPerMile: Int // minutes per mile
    var timeSeconds: Int // minutes
}


struct DashboardView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    // Get the runs, time, and pace for the past week
    @State var statsPerDay: [String: RunStats] = [:]

    @State var totalStepsInWeek: Int = 0
    @State var totalTimeInWeek: Int = 0
    
    @State var averageStepsInWeek: Double = 0
    @State var averageTimeInWeek: Double = 0
    
    @State var stepsPercentageChange: Int = 0
    @State var timePercentageChange: Int = 0
    
    @State var bestPaceInWeek: Int? = nil
        
    private static var weekAgoDate: Date {
        return Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    }
    
    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= weekAgoDate
    }, sort: \Run.postedDate, order: .reverse) var weeklyRuns: [Run]
        
    @Query(sort: \Run.postedDate, order: .reverse) var allRuns: [Run]
        
    // Run a query to fetch the user data
    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}
   
    var gradientColor: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    LIGHT_GREEN.opacity(0.8),
                    LIGHT_GREEN.opacity(0.01),
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    
    // Creates an array of dates spanning the past week up until today
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

    
    
    func generateWeeklyData() {
        
        // date formatter used for indexing into dictionary
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        // Create temporary dictionary for storing stats
        var statsDictionary: [String: RunStats] = Dictionary(uniqueKeysWithValues: days.map { ($0, RunStats(steps: 0, paceMinutesPerMile: 0, timeSeconds: 0 )) })
        
        var totalSteps = 0
        var todaySteps = 0
        var yesterdaySteps = 0
        
        var totalTime = 0
        var todayTime = 0
        var yesterdayTime = 0
        
        var bestPace: Int? = nil
        
        for run in weeklyRuns {
            let dayAbbreviation = dateFormatter.string(from: run.postedDate)
            
            // Update the corresponding stats for current day in dictionary
            if var stats = statsDictionary[dayAbbreviation] {
                stats.steps += run.steps
                stats.paceMinutesPerMile += run.avgPace // this needs to be fixed to take the correct average of average paces
                stats.timeSeconds += run.elapsedTime
                statsDictionary[dayAbbreviation] = stats
            }
            
            if let currentMin = bestPace, run.avgPace != 0 {
                bestPace = min(run.avgPace, currentMin)
            } else {
                bestPace = run.avgPace
            }
            
            
            // Update the total time and steps
            totalTime += run.elapsedTime
            totalSteps += run.steps
            
            if calendar.isDateInToday(run.postedDate) {
                todaySteps += run.steps
                todayTime += run.elapsedTime
            }
            if calendar.isDateInYesterday(run.postedDate) {
                yesterdaySteps += run.steps
                yesterdayTime += run.elapsedTime
            }
        }
        
        self.statsPerDay = statsDictionary
        self.bestPaceInWeek = bestPace
        
        // Update the total steps and time
        self.totalStepsInWeek = totalSteps
        self.totalTimeInWeek = secondsToMinutes(seconds: totalTime)
        
        // Calculate the average steps for this week
        self.averageStepsInWeek = Double(totalSteps) / 7
        self.averageTimeInWeek = Double(secondsToMinutes(seconds: totalTime)) / 7
        
        // update the user's streaks if not already changed
        if yesterdaySteps > 0 && todaySteps > 0{
            if let lastDone = user?.streakLastDoneDate {
                // As long as last done date is not today
                if !calendar.isDateInToday(lastDone) {
                    user?.streakLastDoneDate = Date()
                    user?.streak += 1
                }
            } else {
                // otherwise, we update streak for the first time
                user?.streakLastDoneDate = Date()
                user?.streak += 1
            }
        }
        
        // reset the user's streak if they failed to add steps yesterday
        else if yesterdaySteps == 0 {
            user?.streakLastDoneDate = nil
            user?.streak = 0
        }
        
        // Calculate the percentage change from yesterday's data
        if yesterdaySteps > 0 && yesterdayTime > 0 && todaySteps > 0 && todayTime > 0{
            let stepChange = todaySteps - yesterdaySteps
            let timeChange = todayTime - yesterdayTime
            self.stepsPercentageChange = Int(ceil(Double(stepChange) / Double(yesterdaySteps) * 100))
            self.timePercentageChange = Int(ceil(Double(timeChange) / Double(yesterdayTime) * 100))
        } else {
            self.stepsPercentageChange = 0
            self.timePercentageChange = 0
        }
    }

    
    func getStats(day: String) -> RunStats {
        return statsPerDay[day]!
    }
    

    
    var body: some View {
        NavigationStack {
            
            ScrollView(showsIndicators: false) {
                
                // Container for holding run statistics
                VStack(alignment: .leading){
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        LazyHStack {
                            
                            // Chart to display steps per day
                            VStack {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: -2) {
                                        Text("Steps over last 7 days")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                        
                                        Text("You ran a total of \(totalStepsInWeek) steps")
                                            .font(.caption)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.top, 2)
                                    }
                                    
                                    Spacer()
                                    
                                    if (stepsPercentageChange != 0) {
                                        Text("\(stepsPercentageChange)%")
                                            .foregroundStyle(LIGHT_GREEN)
                                            .fontWeight(.semibold)
                                    }
                                    
                                }
                                .padding(.bottom, 8)
                                
                                if !statsPerDay.isEmpty {
                                    
                                    Chart(days, id: \.self) { day in
                                        
                                        let stats = statsPerDay[day]!
                                        
                                        if self.averageStepsInWeek > 0 {
                                            
                                            // Display the average steps as a horizontal dashed line
                                            RuleMark(y: .value("Average Steps", averageStepsInWeek)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2,2]))
                                                .annotation(position: .top, alignment: .leading) {
                                                    Text(String(format: "Avg: %.2f", self.averageStepsInWeek))
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 2).fill(LIGHT_GREY)
                                                        )
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                }
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                        }
                                        // Show bars for steps per day if nonzero, otherwise display a default bar
                                        if stats.steps > 0{
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Steps", stats.steps)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(day == days.last ? NEON : BAR_GREY)
                                            .annotation {
                                                if day == days.last {
                                                    Text("\(stats.steps)")
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        } 
                                                                                
                                        else{
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Steps", 0)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.0)
                                    .scaleEffect(
                                        x: phase.isIdentity ? 1.0: 0.5,
                                        y: phase.isIdentity ? 1.0: 0.5
                                    )
                                    .offset(y: phase.isIdentity ? 0: 0.5)
                                
                            }
                            
                            // Chart for displaying time
                            VStack {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: -2) {
                                        Text("Time over last 7 days")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                        
                                        Text("You logged a total of \(totalTimeInWeek) minutes")
                                            .font(.caption)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.top, 2)
                                    }
                                    
                                    Spacer()
                                    
                                    if (timePercentageChange != 0) {
                                        Text("\(timePercentageChange)%")
                                            .foregroundStyle(LIGHT_GREEN)
                                            .fontWeight(.semibold)
                                    }
                                    
                                }
                                .padding(.bottom, 8)
                                
                                if !statsPerDay.isEmpty {
                                    
                                    Chart(days, id: \.self) { day in
                                        
                                        let stats = statsPerDay[day]!
                                        
                                        if self.averageTimeInWeek > 0 {
                                            // Display the average time as a horizontal dashed line
                                            RuleMark(y: .value("Average Time", averageTimeInWeek)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2,2]))
                                                .annotation(position: .top, alignment: .leading) {
                                                    Text(String(format:"Avg: %.2f min", self.averageTimeInWeek))
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 2).fill(LIGHT_GREY)
                                                        )
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                }
                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                        }
                                        // Show bars for time per day if nonzero, otherwise display a default bar
                                        if stats.timeSeconds > 0 {
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Time", secondsToMinutes(seconds: stats.timeSeconds))
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(day == days.last ? NEON : BAR_GREY)
                                            .annotation {
                                                if day == days.last {
                                                    Text(String(format: "%.2f", Double(stats.timeSeconds) / 60))
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        } else {
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Steps", 0)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 0) // show one chart per scroll window
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.0)
                                    .scaleEffect(
                                        x: phase.isIdentity ? 1.0: 0.5,
                                        y: phase.isIdentity ? 1.0: 0.5
                                    )
                                    .offset(y: phase.isIdentity ? 0: 0.5)
                            }

                        }
                        .scrollTargetLayout()

                        
                    }
                    .contentMargins(0, for: .scrollContent)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding(.top, 16)
                    .background(.black)
                    
                    
                    Spacer().frame(height: 24)
                    
                    
                    
                    // Second row to hold Pace Line Chart and Daily Streak Information
                    HStack(spacing: 16) {
                        
                        // Average Pace Chart
                        VStack(alignment: .leading) {
                            
                            Text("Pace")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                            
                            Text("Last 7 days")
                                .font(.caption)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                            
                            Spacer().frame(height: 8)
                            
                            if !statsPerDay.isEmpty {
    
                                Chart(days, id: \.self) { day in
                                    
                                    let stats = statsPerDay[day]!
                                        LineMark(
                                            x: .value("Day", day),
                                            y: .value("Pace", stats.paceMinutesPerMile)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(Color.green)
                                        
                                        AreaMark(
                                            x: .value("Day", day),
                                            y: .value("Pace", stats.paceMinutesPerMile)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(gradientColor)
                                    
                                   
                                }
                                .frame(height: 54)
                                .chartYAxis(.hidden)
                                .chartXAxis(.hidden)
                            }
                            HStack {
                                if let bestPaceInWeek {
                                    Text("Best pace \(bestPaceInWeek) min/mile")
                                        .font(.caption)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .padding(.top, 8)
                                }
                            }
                            Spacer()

                        }
                        .padding()
                        .background(LIGHT_GREY)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                                    
                        
                        // Daily Streak
                        VStack(alignment: .leading) {
                        
                            Text("Daily Streak")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                            
                            Text("You're on fire!")
                                .font(.caption)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                            
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                Text("\(user!.streak)")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                    .fontWeight(.heavy)
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(LIGHT_GREY)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)

                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    generateWeeklyData()
                }
                .onChange(of: weeklyRuns) { _, _ in
                    generateWeeklyData()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
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
                
                
                Spacer().frame(height: 24)
                
                
                // Section to display recent run history
                VStack(alignment: .leading) {
                    
                    HStack {
                        Text("Recent Activity")
                            .foregroundStyle(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.bottom, 8)
                        
                        Spacer()
                        
                        NavigationLink(destination: RunHistoryView()) {
                            Text("view all")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .fontWeight(.medium)
                        }
                    }

                    if allRuns.isEmpty {
                        ContentUnavailableView(
                            "No runs were found",
                            systemImage: "figure.run.square.stack.fill",
                            description: Text("Start a new run by clicking on the + symbol")
                        )
                    }
                    else {
                        // Display past runs in a list. Limit to 5 items
                        ForEach(allRuns.prefix(5)) { run in
                            RunCardView(run: run)
                        }
                    }                    
                }
                .padding(.all, 16)
                
                Spacer()
            }
            .background(.black)
            .toolbarBackground(.black, for: .navigationBar)
            .preferredColorScheme(.dark)

        }

    }
}






/*
 
 
 
 // Chart to display time per day
 VStack {
     HStack(alignment: .center) {
         VStack(alignment: .leading, spacing: -2) {
             Text("Time last 7 days")
                 .font(Font.custom("Koulen-Regular", size: 20))
                 .foregroundStyle(.white)
                 .fontWeight(.semibold)
             
             Text("You spent a total of \(totalTimeInWeek) minutes this week")
                 .font(.caption)
                 .foregroundStyle(TEXT_LIGHT_GREY)
         }
         
         Spacer()
         
         if (timePercentageChange > 0) {
             Text("\(timePercentageChange)%")
                 .foregroundStyle(LIGHT_GREEN)
                 .fontWeight(.semibold)
         }
     }
     .padding(.bottom, 8)
                                 
     // Chart to display time in minutes per day
     Chart(days, id: \.self) { day in
         // Show bars for time per day if nonzero, otherwise display a default bar
         if self.statsPerDay[day].timeMinutes > 0 {
             BarMark (
                 x: .value("Day", day),
                 y: .value("Steps", self.statsPerDay[day]!.timeMinutes!)
             )
             .clipShape(RoundedRectangle(cornerRadius: 4))
             .foregroundStyle(NEON)
             .annotation {
                 if day == days.last {
                     Text("\(self.statsPerDay[day]!.timeMinutes!)")
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
 .padding()
 .background(LIGHT_GREY)
 .cornerRadius(16)
 .frame(height: 200)
 */
