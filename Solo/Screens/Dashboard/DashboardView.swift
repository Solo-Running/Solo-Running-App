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

struct RunStatsPerDay {
    var steps: Int
    var paceMinutesPerMile: Int // minutes per mile
    var timeSeconds: Int        // minutes
    var contributedRuns: Int    // the number of runs that fell on this day
}


/**
 Displays a comprehensive overview of a user's statistics over the week as well as
 a preview of the user's recent run sessions.
 */
struct DashboardView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    // Stores the aggregated time, steps, and pace for each day in the past week
    @State var weeklyStats: [String: RunStatsPerDay] = [:]

    @State var totalStepsInWeek: Int = 0
    @State var totalTimeInWeek: Double = 0.0
    
    @State var averageStepsInWeek: Double = 0
    @State var averageTimeInWeek: Double = 0
    
    @State var stepsPercentageChange: Int = 0
    @State var timePercentageChange: Int = 0
    
    @State var bestPaceInWeek: Int = 0
        
    private static var weekAgoDate: Date {
        return Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    }
    
    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= weekAgoDate
    }, sort: \Run.postedDate, order: .reverse) var weeklyRuns: [Run]
        

    static var descriptor: FetchDescriptor<Run> {
        var descriptor = FetchDescriptor<Run>(sortBy: [SortDescriptor(\.postedDate, order: .reverse)])
        descriptor.fetchLimit = 5
        return descriptor
    }
    @Query(descriptor) var recentRuns: [Run]
    
    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}
   
    // Configures the gradient appearance underneath the average pace graph
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
        
        // Date formatter used for indexing into dictionary
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        // Create temporary dictionary for storing stats
        var statsDictionary: [String: RunStatsPerDay] = Dictionary(uniqueKeysWithValues: days.map {
            ($0, RunStatsPerDay(steps: 0, paceMinutesPerMile: 0, timeSeconds: 0, contributedRuns: 0 ))
        })
        
        var totalSteps = 0
        var todaySteps = 0
        var yesterdaySteps = 0
        
        var totalTime = 0
        var todayTime = 0
        var yesterdayTime = 0
        
        var bestPace = 0
        
        for run in weeklyRuns {
            let dayAbbreviation = dateFormatter.string(from: run.postedDate)
            
            // Update the corresponding stats for current day in dictionary
            if var stats = statsDictionary[dayAbbreviation] {
                stats.steps += run.steps
                stats.paceMinutesPerMile += run.avgPace // this needs to be fixed to take the correct average of average paces
                stats.contributedRuns += 1
                stats.timeSeconds += run.elapsedTime
                statsDictionary[dayAbbreviation] = stats
            }
                        
            if run.avgPace > 0 {
                if bestPace == 0 || run.avgPace < bestPace {
                    bestPace = run.avgPace
                }
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
        
        self.weeklyStats = statsDictionary
        self.bestPaceInWeek = bestPace
        
        // Update the total steps and time
        self.totalStepsInWeek = totalSteps
        self.totalTimeInWeek = secondsToMinutes(seconds: totalTime)
        
        // Calculate the average steps for this week
        self.averageStepsInWeek = Double(totalSteps) / 7
        self.averageTimeInWeek = Double(secondsToMinutes(seconds: totalTime)) / 7
                
        
        // update the user's streaks
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
        
        // Calculate the percentage change from yesterday's steps and time
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

    
    func getStats(day: String) -> RunStatsPerDay {
        return weeklyStats[day]!
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
                                        Text("\(stepsPercentageChange > 0 ? "+" : "")\(stepsPercentageChange)%")
                                            .foregroundStyle(stepsPercentageChange > 0 ? TEXT_LIGHT_GREEN : TEXT_LIGHT_RED)
                                            .fontWeight(.semibold)
                                    }
                                    
                                }
                                .padding(.bottom, 8)
                                
                                if !weeklyStats.isEmpty {
                                    
                                    Chart(days, id: \.self) { day in
                                        
                                        let stats = weeklyStats[day]!
                                        
                                        // Show bars for steps per day if nonzero, otherwise display a default bar
                                        if stats.steps > 0{
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Steps", stats.steps)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(day == days.last ? BLUE : BAR_GREY)
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
                                        
                                        Text(String(format: "You logged a total of %.2f minutes", totalTimeInWeek ))
                                            .font(.caption)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .padding(.top, 2)
                                    }
                                    
                                    Spacer()
                                    
                                    if (timePercentageChange != 0) {
                                        Text("\(timePercentageChange > 0 ? "+" : "")\(timePercentageChange)%")
                                            .foregroundStyle(timePercentageChange > 0 ? TEXT_LIGHT_GREEN : TEXT_LIGHT_RED)
                                            .fontWeight(.semibold)
                                    }
                                    
                                }
                                .padding(.bottom, 8)
                                
                                if !weeklyStats.isEmpty {
                                    
                                    Chart(days, id: \.self) { day in
                                        
                                        let statsForDay = weeklyStats[day]!
                                        let minutesForDay =  Double(statsForDay.timeSeconds) / 60.0


                                        if minutesForDay > 0 {
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Time", minutesForDay)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(day == days.last ? BLUE : BAR_GREY)
                                            .annotation {
                                                if day == days.last {
                                                    Text(String(format: "%.2f", minutesForDay))
                                                        .font(.caption)
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        else if statsForDay.timeSeconds == 0 {
                                            BarMark (
                                                x: .value("Day", day),
                                                y: .value("Steps", 0)
                                            )
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
                    .padding(.vertical, 16)
                    .background(.black)
                    

                    
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
                            
                            if !weeklyStats.isEmpty {
    
                                Chart(days, id: \.self) { day in
                                    
                                    let stats = weeklyStats[day]!
                                        LineMark(
                                            x: .value("Day", day),
                                            y: .value("Pace", stats.contributedRuns > 0 ? Int(stats.paceMinutesPerMile / stats.contributedRuns) : 0)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(Color.green)
                                        
                                        AreaMark(
                                            x: .value("Day", day),
                                            y: .value("Pace", stats.contributedRuns > 0 ? Int(stats.paceMinutesPerMile / stats.contributedRuns) : 0)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(gradientColor)
                                   
                                }
                                .frame(height: 54)
                                .chartYAxis(.hidden)
                                .chartXAxis(.hidden)
                            }
                            HStack {
                                if bestPaceInWeek > 0 {
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
                            
                            switch user!.streak {
                            case 0:
                                Text("Start logging runs!")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            case 1..<10:
                                Text("Keep it up!")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            case 11..<20:
                                Text("You're on fire!")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            case 21..<50:
                                Text("You can do it!")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            default:
                                Text("Amazing job")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                      
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

                    if recentRuns.isEmpty {
                        ContentUnavailableView(
                            "No runs were found",
                            systemImage: "figure.run.square.stack.fill",
                            description: Text("Start a new run by tapping on the + symbol")
                        )
                    }
                    else {
                        // Display past runs in a list. Limit to 5 items
                        ForEach(recentRuns) { run in
                            NavigationLink(destination: RunDetailView(runData: run)) {
                                
                                HStack(alignment: .top) {
                                    
                                    if let data = run.routeImage {
                                        VStack {
                                            Image(uiImage: UIImage(data: data)!)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .frame(width: 80, height: 80 )
                                        .padding(.trailing, 8)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        
                                        // Grab the abbreviated month and day
                                        Text(run.startTime.formatted(
                                            .dateTime
                                            .day()
                                            .month(.abbreviated)
                                        ))
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .fontWeight(.bold)
                                        .padding(.bottom, 0)
                                        
                                        Text("\(convertDateToTime(date: run.startTime)) - \(convertDateToTime(date: run.endTime))")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .font(.subheadline)
                                        
                                        HStack  {
                                            
                                            // Custom pin
                                            VStack {
                                                ZStack {
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 14, height: 14)
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.title2)
                                                        .foregroundStyle(run.endPlacemark!.isCustomLocation ? .yellow : DARK_GREY)
                                                        .font(.system(size: 4))
                                                }
                                                
                                                Image(systemName: "arrowtriangle.down.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(run.endPlacemark!.isCustomLocation ? .yellow : DARK_GREY)
                                                    .offset(x: 0, y: -8)
                                            }
                                                                                    
                                            Text(run.endPlacemark!.name)
                                                .foregroundStyle(.white)
                                                .padding(.bottom, 4)
                                                .font(.system(size: 14))
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
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
