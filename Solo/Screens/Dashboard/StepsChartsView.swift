//
//  StepsChartsView.swift
//  Solo
//
//  Created by William Kim on 3/9/25.
//

import Foundation
import SwiftUI
import SwiftData
import Charts


struct StepsData: Identifiable {
    let id = UUID()
    var steps: Int = 0
    var distance: Double = 0.0
    var date: Date = Date()
    var contributedRuns: Int = 0
    var animate: Bool = false
}


struct StepsChartsView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    static var calendar = Calendar.current
    static var currentDay: Int = calendar.component(.day, from: Date())
    static var currentMonth: Int = calendar.component(.month, from: Date())
    static var currentYear: Int = calendar.component(.year, from: Date())
        
    static private var weekAgoDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    static private var monthAgoDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    static private var yearAgoDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date())!

    @State private var timePeriod: TimePeriod = .Week
    @State private var selectedWeekDay: Date?
    @State private var selectedMonthDay: Date?
    @State private var selectedYearMonth: Date?
    
    
    private var selectedStepsDataForWeekDay: StepsData? {
        guard let selectedWeekDay else { return nil }
        return weeklySteps.first {
            Calendar.current.isDate(selectedWeekDay, equalTo: $0.date, toGranularity: .day)
        }
    }
    
    private var selectedStepsDataForMonthDay: StepsData? {
        guard let selectedMonthDay else { return nil }
        return monthlySteps.first {
            Calendar.current.isDate(selectedMonthDay, equalTo: $0.date, toGranularity: .day)
        }
    }
    
    private var selectedStepsDataForYearMonth: StepsData? {
        guard let selectedYearMonth else { return nil }
        return yearlySteps.first {
            Calendar.current.isDate(selectedYearMonth, equalTo: $0.date, toGranularity: .month)
        }
    }
    
    @State private var editChartStyleSheetDetents: Set<PresentationDetent> = [.fraction(0.35)]
    @State private var isShowingEditChartStyleSheet: Bool = false
    @AppStorage("isStepsBarChartPresentation") var isStepsBarChartPresentation = true
    @AppStorage("isConvertingStepsToMiles") var isConvertingStepsToMiles = false
    
    @State var weeklySteps: [StepsData] = []
    @State var monthlySteps: [StepsData] = []
    @State var yearlySteps: [StepsData] = []

    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= weekAgoDate
    }, sort: \Run.postedDate, order: .reverse) var weeklyRuns: [Run]
    
    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= monthAgoDate
    }, sort: \Run.postedDate, order: .reverse) var monthlyRuns: [Run]
    
    @Query(filter: #Predicate<Run> { run in
        return run.postedDate >= yearAgoDate
    }, sort: \Run.postedDate, order: .reverse) var yearlyRuns: [Run]
    
    @Query var userData: [User]
    var user: User? {userData.first}
    
    
    @State var furthestRun: Run?
    @State var averageSteps: Int = 0
    @State var totalSteps: Int = 0
    
    
    func animateWeeklyData() {
        for (index, _) in weeklySteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    weeklySteps[index].animate = true
                }
            }
        }
    }
    
    func animateMonthlyData() {
        for (index, _) in monthlySteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    monthlySteps[index].animate = true
                }
            }
        }
    }
    
    func animateYearlyData() {
        for (index, _) in yearlySteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    yearlySteps[index].animate = true
                }
            }
        }
    }
    
    func generateWeeklyData() {
        if weeklySteps.count > 0 {
            return
        }
        
        let last7Days = (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: Date()))! }.reversed()

        // Testing purposes: let randInt = Int.random(in: 100...300000)
        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: StepsData] = Dictionary(uniqueKeysWithValues: last7Days.map {
            ($0, StepsData(steps: 0, date: $0, contributedRuns: 0))
        })
        
        for run in weeklyRuns {
            let runDate = Calendar.current.startOfDay(for: run.postedDate)
            if var data = dictionary[runDate] {
                data.steps += run.steps
                data.distance += run.distanceTraveled
                data.contributedRuns += 1
                data.date = runDate
                dictionary[runDate] = data
            }
        }
        self.weeklySteps = dictionary.values.sorted { $0.date < $1.date }
    }
    
    func generateMonthlyData() {
        if monthlySteps.count > 0 {
            return
        }
        
        let last30days = (0..<30).map { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: Date()))! }.reversed()
        
        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: StepsData] = Dictionary(uniqueKeysWithValues: last30days.map {
            ($0, StepsData(steps: 0, date: $0, contributedRuns: 0))
        })
        
        for run in monthlyRuns {
            let runDate = Calendar.current.startOfDay(for: run.postedDate)
            if var data = dictionary[runDate] {
                data.steps += run.steps
                data.distance += run.distanceTraveled
                data.contributedRuns += 1
                data.date = runDate
                dictionary[runDate] = data
            }
        }
        self.monthlySteps = dictionary.values.sorted { $0.date < $1.date }
    }
    
    func generateYearlyData() {
        if yearlySteps.count > 0 {
            return
        }
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: Date())
        let startOfMonth = Calendar.current.date(from: dateComponents)!
        
        let last12Months = (0..<12).map { Calendar.current.date(byAdding: .month, value: -$0, to: startOfMonth)! }.reversed()
        
        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: StepsData] = Dictionary(uniqueKeysWithValues: last12Months.map {
            ($0, StepsData(steps: 0, date: $0, contributedRuns: 0))
        })
        
        for run in yearlyRuns {
            let runDateComponents = Calendar.current.dateComponents([.year, .month], from: run.postedDate)
            let startOfMonth = Calendar.current.date(from: runDateComponents)!
            
            if var data = dictionary[startOfMonth] {
                data.steps += run.steps
                data.distance += run.distanceTraveled
                data.contributedRuns += 1
                data.date = startOfMonth
                dictionary[startOfMonth] = data
            }
        }
        self.yearlySteps = dictionary.values.sorted { $0.date < $1.date }
    }
    
    
    func generateSummaryStatistics() {
        
        if totalSteps > 0 || averageSteps > 0 || furthestRun != nil {
            return
        }
        
        let allRunsDescriptor = FetchDescriptor<Run>()
        let allRuns = (try? modelContext.fetch(allRunsDescriptor)) ?? []
        let totalRuns = (try? modelContext.fetchCount(allRunsDescriptor)) ?? 0
        
        for run in allRuns {
            totalSteps += run.steps
            if furthestRun == nil {
                furthestRun = run
            } else {
                if (furthestRun!.steps < run.steps) && (run.steps > 0) {
                    furthestRun = run
                }
            }
        }
        
        if totalRuns > 0 {
            averageSteps = Int(Double(totalSteps) / Double(totalRuns))
        }
    }

    
    var body: some View {
                
        ScrollView {
            
            Picker("Select a time period", selection: $timePeriod) {
                Text("W").tag(TimePeriod.Week)
                Text("30D").tag(TimePeriod.Month)
                Text("Y").tag(TimePeriod.Year)
            }
            .disabled(subscriptionManager.hasSubscriptionExpired())
            .pickerStyle(.segmented)
            .padding(.top, 24)
            
            
            VStack {
                if subscriptionManager.hasSubscriptionExpired() {
                    VStack {
                        if !weeklySteps.isEmpty {
                            
                            let dateFormatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "d\nE" // "Tue 19", "Wed 20"
                                return formatter
                            }()
                            
                            let totalSteps = weeklySteps.reduce( 0, {$0 + $1.steps})
                            let totalDistance = weeklySteps.reduce(0, {$0 + $1.distance})
                            
                            let maxSteps = weeklySteps.max { item1, item2 in
                                return item2.steps > item1.steps
                            }?.steps ?? 0
                            
                            // Distance is in meters by default
                            let maxDistance = weeklySteps.max { item1, item2 in
                                return item2.distance > item1.distance
                            }?.distance ?? 0
                            
                            
                            VStack(alignment: .leading) {
                                if isConvertingStepsToMiles {
                                    Text(String(format:"%.2f mi", totalDistance / 1609.344))
                                        .font(.largeTitle).bold()
                                    Text("Total miles this week")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                } else {
                                    Text("\(totalSteps)").font(.largeTitle).bold()
                                    Text("Total steps this week")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16 )
                            
                            Chart {
                                // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                if let selectedStepsDataForWeekDay {
                                    RuleMark(x: .value("Selected day", selectedStepsDataForWeekDay.date, unit: .day))
                                        .foregroundStyle(.secondary.opacity(0.3))
                                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                            VStack(alignment: .leading) {
                                                Text(selectedStepsDataForWeekDay.date, format: .dateTime.month(.wide).day().year())
                                                    .font(.subheadline)
                                                    .bold()
                                                
                                                if isConvertingStepsToMiles {
                                                    Text(String(format:"%.2f mi", selectedStepsDataForWeekDay.distance / 1609.344))
                                                        .font(.title3)
                                                        .bold()
                                                } else {
                                                    Text("\(selectedStepsDataForWeekDay.steps)")
                                                        .font(.title3)
                                                        .bold()
                                                }
                                            }
                                            .padding(8)
                                            .frame(width: 154, alignment: .leading)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                        }
                                }
                                
                                ForEach(weeklySteps) { stepsForDay in
                                    let miles = stepsForDay.distance / 1609.344
                                    
                                    
                                    if stepsForDay.steps > 0 {
                                        if isStepsBarChartPresentation {
                                            BarMark (
                                                x: .value("Day", stepsForDay.date, unit: .day),
                                                y: .value("Steps", stepsForDay.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps))  : 0)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(LIGHT_GREEN)
                                        } else {
                                            LineMark(
                                                x: .value("Day", stepsForDay.date, unit: .day),
                                                y: .value("Steps", stepsForDay.animate ?  ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps)) : 0)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(LIGHT_GREEN)
                                        }
                                    }
                                    else{
                                        if isStepsBarChartPresentation {
                                            BarMark (
                                                x: .value("Day", stepsForDay.date, unit: .day),
                                                y: .value("Steps", 0)
                                            )
                                        } else {
                                            LineMark(
                                                x: .value("Day", stepsForDay.date, unit: .day),
                                                y: .value("Steps", 0)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(LIGHT_GREEN)
                                        }
                                     
                                    }
                                }
                            }
                            .onAppear {
                                animateWeeklyData()
                            }
                            .chartYScale(domain: 0...(isConvertingStepsToMiles ? (maxDistance / 1609.344) : Double(maxSteps)))
                            .chartXSelection(value: $selectedWeekDay.animation(.spring))
                            .chartXAxis {
                                AxisMarks { value in
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel {
                                            Text(dateFormatter.string(from: date))
                                                .multilineTextAlignment(.center)
                                                .padding(.leading, 10)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel() {
                                        if let intValue = value.as(Int.self) {
                                            Text(intValue.formatted(.number.notation(.compactName)))
                                        }
                                    }
                                }
                            }
                            .frame(height: 280)
                            
                        }
                    }
                    .frame(height: 420)
                } else {
                    // Display for charts
                    TabView(selection: $timePeriod) {
                        
                        // Weekly steps view
                        VStack {
                            if !weeklySteps.isEmpty {
                                
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "d\nE" // "Tue 19", "Wed 20"
                                    return formatter
                                }()
                                
                                let totalSteps = weeklySteps.reduce( 0, {$0 + $1.steps})
                                let totalDistance = weeklySteps.reduce(0, {$0 + $1.distance})
                                
                                let maxSteps = weeklySteps.max { item1, item2 in
                                    return item2.steps > item1.steps
                                }?.steps ?? 0
                                
                                // Distance is in meters by default
                                let maxDistance = weeklySteps.max { item1, item2 in
                                    return item2.distance > item1.distance
                                }?.distance ?? 0
                                
                                
                                VStack(alignment: .leading) {
                                    if isConvertingStepsToMiles {
                                        Text(String(format:"%.2f mi", totalDistance / 1609.344))
                                            .font(.largeTitle).bold()
                                        Text("Total miles this week")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    } else {
                                        Text("\(totalSteps)").font(.largeTitle).bold()
                                        Text("Total steps this week")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedStepsDataForWeekDay {
                                        RuleMark(x: .value("Selected day", selectedStepsDataForWeekDay.date, unit: .day))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedStepsDataForWeekDay.date, format: .dateTime.month(.wide).day().year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    
                                                    if isConvertingStepsToMiles {
                                                        Text(String(format:"%.2f mi", selectedStepsDataForWeekDay.distance / 1609.344))
                                                            .font(.title3)
                                                            .bold()
                                                    } else {
                                                        Text("\(selectedStepsDataForWeekDay.steps)")
                                                            .font(.title3)
                                                            .bold()
                                                    }
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(weeklySteps) { stepsForDay in
                                        let miles = stepsForDay.distance / 1609.344
                                        
                                        if stepsForDay.steps > 0 {
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", stepsForDay.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps))  : 0)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", stepsForDay.animate ?  ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps)) : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else{
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                    }
                                    
                                }
                                .onAppear {
                                    animateWeeklyData()
                                }
                                .chartYScale(domain: 0...(isConvertingStepsToMiles ? (maxDistance / 1609.344) : Double(maxSteps)))
                                .chartXSelection(value: $selectedWeekDay.animation(.spring))
                                .chartXAxis {
                                    AxisMarks { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(dateFormatter.string(from: date))
                                                    .multilineTextAlignment(.center)
                                                    .padding(.leading, 10)
                                                    .padding(.top, 2)
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel() {
                                            if let intValue = value.as(Int.self) {
                                                Text(intValue.formatted(.number.notation(.compactName)))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 280)
                            }
                        }
                        .tag(TimePeriod.Week)
                        
                        // Monthly steps view
                        VStack {
                            if !monthlySteps.isEmpty {
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "d" // "Tue 19", "Wed 20"
                                    return formatter
                                }()
                                
                                let totalSteps = monthlySteps.reduce( 0, {$0 + $1.steps})
                                let totalDistance = monthlySteps.reduce(0, {$0 + $1.distance})
                                
                                let maxSteps = monthlySteps.max { item1, item2 in
                                    return item2.steps > item1.steps
                                }?.steps ?? 0
                                
                                // Distance is in meters by default
                                let maxDistance = monthlySteps.max { item1, item2 in
                                    return item2.distance > item1.distance
                                }?.distance ?? 0
                                
                                
                                VStack(alignment: .leading) {
                                    if isConvertingStepsToMiles {
                                        Text(String(format:"%.2f mi", totalDistance / 1609.344))
                                            .font(.largeTitle).bold()
                                        Text("Total miles last 30 days")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    } else {
                                        Text("\(totalSteps)").font(.largeTitle).bold()
                                        Text("Total steps last 30 days")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedStepsDataForMonthDay {
                                        RuleMark(x: .value("Selected day", selectedStepsDataForMonthDay.date, unit: .day))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedStepsDataForMonthDay.date, format: .dateTime.month(.wide).day().year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    if isConvertingStepsToMiles {
                                                        Text(String(format:"%.2f mi", selectedStepsDataForMonthDay.distance / 1609.344))
                                                            .font(.title3)
                                                            .bold()
                                                    } else {
                                                        Text("\(selectedStepsDataForMonthDay.steps)")
                                                            .font(.title3)
                                                            .bold()
                                                    }
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(monthlySteps) { stepsForDay in
                                        let miles = stepsForDay.distance / 1609.344
                                        
                                        if stepsForDay.steps > 0{
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", stepsForDay.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps)) : 0 )
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 1))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", stepsForDay.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForDay.steps))  : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else {
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForDay.date, unit: .day),
                                                    y: .value("Steps", 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                    }
                                    
                                }
                                .chartYScale(domain: 0...(isConvertingStepsToMiles ? (maxDistance / 1609.344) : Double(maxSteps)))
                                .onAppear {
                                    animateMonthlyData()
                                }
                                .chartXSelection(value: $selectedMonthDay.animation(.spring))
                                .chartXAxis {
                                    AxisMarks { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(dateFormatter.string(from: date))
                                                    .multilineTextAlignment(.center)
                                                    .padding(.top, 2)
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel() {
                                            if let intValue = value.as(Int.self) {
                                                Text(intValue.formatted(.number.notation(.compactName)))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 280)
                                
                                Spacer()
                            }
                        }
                        .tag(TimePeriod.Month)
                        
                        // Yearly steps view
                        VStack {
                            if !yearlySteps.isEmpty {
                                
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "MMM" // Mar, Apr, May, etc
                                    return formatter
                                }()
                                
                                let totalSteps = yearlySteps.reduce( 0, {$0 + $1.steps})
                                let totalDistance = yearlySteps.reduce(0, {$0 + $1.distance})
                                
                                let maxSteps = yearlySteps.max { item1, item2 in
                                    return item2.steps > item1.steps
                                }?.steps ?? 0
                                
                                // Distance is in meters by default
                                let maxDistance = yearlySteps.max { item1, item2 in
                                    return item2.distance > item1.distance
                                }?.distance ?? 0
                                
                                
                                VStack(alignment: .leading) {
                                    if isConvertingStepsToMiles {
                                        Text(String(format:"%.2f mi", totalDistance / 1609.344))
                                            .font(.largeTitle).bold()
                                        Text("Total miles this year")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    } else {
                                        Text("\(totalSteps)").font(.largeTitle).bold()
                                        Text("Total steps this year")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedStepsDataForYearMonth {
                                        RuleMark(x: .value("Selected month", selectedStepsDataForYearMonth.date, unit: .month))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedStepsDataForYearMonth.date, format: .dateTime.month(.wide).year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    
                                                    if isConvertingStepsToMiles {
                                                        Text(String(format:"%.2f mi", selectedStepsDataForYearMonth.distance / 1609.344))
                                                            .font(.title3)
                                                            .bold()
                                                    } else {
                                                        Text("\(selectedStepsDataForYearMonth.steps)")
                                                            .font(.title3)
                                                            .bold()
                                                    }
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(yearlySteps) { stepsForMonth in
                                        let miles = stepsForMonth.distance / 1609.344
                                        
                                        if stepsForMonth.steps > 0{
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Month", stepsForMonth.date, unit: .month),
                                                    y: .value("Steps", stepsForMonth.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForMonth.steps))  : 0)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 1))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForMonth.date, unit: .month),
                                                    y: .value("Steps", stepsForMonth.animate ? ( isConvertingStepsToMiles ? miles : Double(stepsForMonth.steps)) : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else {
                                            if isStepsBarChartPresentation {
                                                BarMark (
                                                    x: .value("Month", stepsForMonth.date, unit: .month),
                                                    y: .value("Steps", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", stepsForMonth.date, unit: .month),
                                                    y: .value("Steps", 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                    }
                                }
                                .onAppear {
                                    animateYearlyData()
                                }
                                .chartYScale(domain: 0...(isConvertingStepsToMiles ? (maxDistance / 1609.344) : Double(maxSteps)))
                                .chartXSelection(value: $selectedYearMonth.animation(.spring))
                                .chartXAxis {
                                    AxisMarks { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(dateFormatter.string(from: date))
                                                    .multilineTextAlignment(.center)
                                                    .padding(.top, 2)
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel() {
                                            if let intValue = value.as(Int.self) {
                                                Text(intValue.formatted(.number.notation(.compactName)))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 280)
                                
                                Spacer()
                            }
                        }
                        .tag(TimePeriod.Year)
                    }
                    .animation(.spring, value: timePeriod)
                    .transition(.slide.animation(.spring))
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 420)
                }
                
                HStack(alignment: .center) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    
                    Text("Press and hold the chart for more details.")
                        .font(.caption)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    
                    Spacer()
                }
                
                Spacer().frame(height: 24)
                
                // Summary statistics sections
                VStack(alignment: .leading, spacing: 24) {
                    
                    Text("Statistics")
                        .font(.title3)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .fontWeight(.semibold)
                    
                    // Total Steps taken so far
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(LIGHT_GREY))
                        
                        VStack(alignment: .leading) {
                            let miles = Double(totalSteps) / 1609.344

                            if isConvertingStepsToMiles {
                                Text("Total miles")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .bold()
                                
                                Text(String(format:"%.2f", miles))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            } else {
                                Text("Total steps")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .bold()
                                
                                Text("\(formattedNumber(totalSteps))")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    
                    
                    // The max steps taken and which day
                    VStack {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(LIGHT_GREY))
                            
                            if let run = furthestRun, run.steps > 0{
                                VStack(alignment: .leading) {
                                    let miles = Double(run.steps) / 1609.344

                                    if isConvertingStepsToMiles {
                                        Text(String(format:"%.2f most miles", miles))
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .bold()
                                    } else {
                                        Text("\(formattedNumber(run.steps)) most steps")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .bold()
                                    }
                                    
                                    HStack(alignment: .center, spacing: 4) {
                                        Text(run.endTime.formatted(
                                            .dateTime.month(.wide).day().year().hour().minute().locale(.current)
                                        ))
                                        .font(.title3)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                        .fontWeight(.semibold)

                                        Spacer()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack {
                                    Text("No furthest run recorded")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .bold()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                
                    
                    // Average steps per day for all runs
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Image(systemName: "waveform")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(LIGHT_GREY))
                        
                        
                        VStack(alignment: .leading) {
                            let miles = Double(averageSteps) / 1609.344
                            
                            if isConvertingStepsToMiles {
                                Text("Avg miles")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .bold()
                                
                                Text(String(format:"%.2f per run", miles))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            } else {
                                Text("Avg steps")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .bold()
                                
                                Text("\(formattedNumber(averageSteps)) per run")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                                
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    
                    
                    Spacer().frame(height: 64)
                    
                }
            }
            .sheet(isPresented: $isShowingEditChartStyleSheet) {
                VStack(alignment: .leading) {
                    
                    Text("Chart Settings")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .bold()
                    
                    Spacer().frame(height: 24)
                    
                    HStack(alignment: .center) {
                        HStack(alignment: .center) {
                            Text("Use line charts")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                            
                            if subscriptionManager.hasSubscriptionExpired() {
                                Text("Pro")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(BLUE))
                            }
                        }
                        
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !isStepsBarChartPresentation },
                            set: { isStepsBarChartPresentation = !$0 }
                        ))
                            .disabled(subscriptionManager.hasSubscriptionExpired())
                            .toggleStyle(SwitchToggleStyle(tint: TEXT_LIGHT_GREY))
                            .frame(maxWidth: 48)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    
                    Spacer().frame(height: 16)
                    
                    HStack(alignment: .center) {
                        HStack(alignment: .center){
                            Text("Convert to miles")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                            
                            if subscriptionManager.hasSubscriptionExpired() {
                                Text("Pro")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(BLUE))
                                
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isConvertingStepsToMiles)
                            .disabled(subscriptionManager.hasSubscriptionExpired())
                            .toggleStyle(SwitchToggleStyle(tint: TEXT_LIGHT_GREY))
                            .frame(maxWidth: 48)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    
                    
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .presentationDetents(editChartStyleSheetDetents)
                .frame(maxHeight: .infinity, alignment: .top)
                .presentationBackground(.black)
                .presentationDragIndicator(.visible)
            }
            
        }
        .padding(.horizontal, 16)
        .scrollIndicators(.hidden)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Steps")
                    .fontWeight(.semibold)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingEditChartStyleSheet = true
                } label : {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            generateWeeklyData()
            generateSummaryStatistics()
            
            if subscriptionManager.hasSubscriptionExpired() {
                isConvertingStepsToMiles = false
                isStepsBarChartPresentation = true
            } else {
                generateMonthlyData()
                generateYearlyData()
            }
        }
    }
}
