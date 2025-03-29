//
//  TimeChartsView.swift
//  Solo
//
//  Created by William Kim on 3/13/25.
//

import Foundation
import SwiftUI
import SwiftData
import Charts

struct TimeData: Identifiable {
    let id = UUID()
    var timeMinutes: Int = 0
    var date: Date = Date()
    var contributedRuns: Int = 0
    var animate: Bool = false
}


struct TimeChartsView: View {
    
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.modelContext) var modelContext
    
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
    
    private var selectedTimeDataForWeekDay: TimeData? {
        guard let selectedWeekDay else { return nil }
        return weeklyTime.first {
            Calendar.current.isDate(selectedWeekDay, equalTo: $0.date, toGranularity: .day)
        }
    }
    
    private var selectedTimeDataForMonthDay: TimeData? {
        guard let selectedMonthDay else { return nil }
        return monthlyTime.first {
            Calendar.current.isDate(selectedMonthDay, equalTo: $0.date, toGranularity: .day)
        }
    }
    
    private var selectedTimeDataForYearMonth: TimeData? {
        guard let selectedYearMonth else { return nil }
        return yearlyTime.first {
            Calendar.current.isDate(selectedYearMonth, equalTo: $0.date, toGranularity: .month)
        }
    }
    
    @State private var editChartStyleSheetDetents: Set<PresentationDetent> = [.fraction(0.35)]
    @State private var isShowingEditChartStyleSheet: Bool = false
    @AppStorage("isTimeBarChartPresentation") var isTimeBarChartPresentation = true
    
    @State var weeklyTime: [TimeData] = []
    @State var monthlyTime: [TimeData] = []
    @State var yearlyTime: [TimeData] = []

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
    
    @State var averageTime: Int = 0
    @State var totalTime: Int = 0
    
    
    func animateWeeklyData() {
        for (index, _) in weeklyTime.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    weeklyTime[index].animate = true
                }
            }
        }
    }
    
    func animateMonthlyData() {
        for (index, _) in monthlyTime.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    monthlyTime[index].animate = true
                }
            }
        }
    }
    
    func animateYearlyData() {
        for (index, _) in yearlyTime.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8 )) {
                    yearlyTime[index].animate = true
                }
            }
        }
    }
    
    func generateWeeklyData() {
        if weeklyTime.count > 0 {
            return
        }
        
        let last7Days = (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: Date()))! }.reversed()

        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: TimeData] = Dictionary(uniqueKeysWithValues: last7Days.map {
            ($0, TimeData(timeMinutes: 0, date: $0, contributedRuns: 0))
        })
        
        for run in weeklyRuns {
            let runDate = Calendar.current.startOfDay(for: run.postedDate)
            if var data = dictionary[runDate] {
                data.timeMinutes += secondsToMinutes(seconds: run.elapsedTime)
                data.contributedRuns += 1
                data.date = runDate
                dictionary[runDate] = data
            }
        }
        self.weeklyTime = dictionary.values.sorted { $0.date < $1.date }
    }
    
    func generateMonthlyData() {
        if monthlyTime.count > 0 {
            return
        }
        
        let last30days = (0..<30).map { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: Date()))! }.reversed()
        
        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: TimeData] = Dictionary(uniqueKeysWithValues: last30days.map {
            ($0, TimeData(timeMinutes: 0, date: $0, contributedRuns: 0))
        })
        
        for run in monthlyRuns {
            let runDate = Calendar.current.startOfDay(for: run.postedDate)
            if var data = dictionary[runDate] {
                data.timeMinutes += secondsToMinutes(seconds: run.elapsedTime)
                data.contributedRuns += 1
                data.date = runDate
                dictionary[runDate] = data
            }
        }
        self.monthlyTime = dictionary.values.sorted { $0.date < $1.date }
    }
    
    func generateYearlyData() {
        if yearlyTime.count > 0 {
            return
        }
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: Date())
        let startOfMonth = Calendar.current.date(from: dateComponents)!
        
        let last12Months = (0..<12).map { Calendar.current.date(byAdding: .month, value: -$0, to: startOfMonth)! }.reversed()
        
        // Calculate summary statistics for each day in this week using a dictionary
        var dictionary: [Date: TimeData] = Dictionary(uniqueKeysWithValues: last12Months.map {
            ($0, TimeData(timeMinutes: 0, date: $0, contributedRuns: 0))
        })
        
        for run in yearlyRuns {
            let runDateComponents = Calendar.current.dateComponents([.year, .month], from: run.postedDate)
            let startOfMonth = Calendar.current.date(from: runDateComponents)!
            
            if var data = dictionary[startOfMonth] {
                data.timeMinutes += secondsToMinutes(seconds: run.elapsedTime)
                data.contributedRuns += 1
                data.date = startOfMonth
                dictionary[startOfMonth] = data
            }
        }
        self.yearlyTime = dictionary.values.sorted { $0.date < $1.date }
    }
    
    
    func generateSummaryStatistics() {
        
        if totalTime > 0 || averageTime > 0 {
            return
        }
        
        let allRunsDescriptor = FetchDescriptor<Run>()
        let allRuns = (try? modelContext.fetch(allRunsDescriptor)) ?? []
        let totalRuns = (try? modelContext.fetchCount(allRunsDescriptor)) ?? 0
        
        for run in allRuns {
            totalTime += secondsToMinutes(seconds: run.elapsedTime)
        }
        
        if totalRuns > 0 {
            averageTime = Int(Double(totalTime) / Double(totalRuns))
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
                        if !weeklyTime.isEmpty {
                            
                            let dateFormatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "d\nE" // "Tue 19", "Wed 20"
                                return formatter
                            }()
                            
                            let totalWeeklyTime = weeklyTime.reduce( 0, {$0 + $1.timeMinutes})
                            
                            let maxTime = Double(weeklyTime.max { item1, item2 in
                                return item2.timeMinutes > item1.timeMinutes
                            }?.timeMinutes ?? 0) / 60.0
                            
                            VStack(alignment: .leading) {
                                Text("\(minutesToFormattedTime(minutes: totalWeeklyTime))").font(.largeTitle).bold()
                                Text("Total time this week")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16 )
                            
                            Chart {
                                // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                if let selectedTimeDataForWeekDay {
                                    RuleMark(x: .value("Selected day", selectedTimeDataForWeekDay.date, unit: .day))
                                        .foregroundStyle(.secondary.opacity(0.3))
                                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                            VStack(alignment: .leading) {
                                                Text(selectedTimeDataForWeekDay.date, format: .dateTime.month(.wide).day().year())
                                                    .font(.subheadline)
                                                    .bold()
                                                
                                                Text("\(minutesToFormattedTime(minutes: selectedTimeDataForWeekDay.timeMinutes))")
                                                    .font(.title3)
                                                    .bold()
                                                
                                            }
                                            .padding(8)
                                            .frame(width: 154, alignment: .leading)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                        }
                                }
                                
                                ForEach(weeklyTime) { timeForDay in
                                    let hours = (Double(timeForDay.timeMinutes) / 60.0)
                                    
                                    if timeForDay.timeMinutes > 0 {
                                        if isTimeBarChartPresentation {
                                            BarMark (
                                                x: .value("Day", timeForDay.date, unit: .day),
                                                y: .value("Time", timeForDay.animate ? hours : 0)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .foregroundStyle(LIGHT_GREEN)
                                        } else {
                                            LineMark(
                                                x: .value("Day", timeForDay.date, unit: .day),
                                                y: .value("Time", timeForDay.animate ? hours : 0)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(LIGHT_GREEN)
                                        }
                                    }
                                    else{
                                        if isTimeBarChartPresentation {
                                            BarMark (
                                                x: .value("Day", timeForDay.date, unit: .day),
                                                y: .value("Time", 0)
                                            )
                                        } else {
                                            LineMark(
                                                x: .value("Day", timeForDay.date, unit: .day),
                                                y: .value("Time", 0)
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
                            .chartYScale(domain: 0...(maxTime))
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
                            .frame(height: 280)
                            
                            HStack(alignment: .center) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                
                                Text("Press and hold the chart for more details.")
                                    .multilineTextAlignment(.leading)
                                    .font(.caption)
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            
                            Spacer()
                            
                        }
                    }
                    .frame(height: 420)

                } else {
                    // Display for charts
                    TabView(selection: $timePeriod) {
                        
                        // Weekly time view
                        VStack {
                            if !weeklyTime.isEmpty {
                                
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "d\nE" // "Tue 19", "Wed 20"
                                    return formatter
                                }()
                                
                                let totalWeeklyTime = weeklyTime.reduce( 0, {$0 + $1.timeMinutes})
                                
                                let maxTime = Double(weeklyTime.max { item1, item2 in
                                    return item2.timeMinutes > item1.timeMinutes
                                }?.timeMinutes ?? 0) / 60.0
                                
                                VStack(alignment: .leading) {
                                    Text("\(minutesToFormattedTime(minutes: totalWeeklyTime))").font(.largeTitle).bold()
                                    Text("Total time this week")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedTimeDataForWeekDay {
                                        RuleMark(x: .value("Selected day", selectedTimeDataForWeekDay.date, unit: .day))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedTimeDataForWeekDay.date, format: .dateTime.month(.wide).day().year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    
                                                    Text("\(minutesToFormattedTime(minutes: selectedTimeDataForWeekDay.timeMinutes))")
                                                        .font(.title3)
                                                        .bold()
                                                    
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(weeklyTime) { timeForDay in
                                        let hours = (Double(timeForDay.timeMinutes) / 60.0)
                                        
                                        if timeForDay.timeMinutes > 0 {
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", timeForDay.animate ? hours : 0)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", timeForDay.animate ? hours : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else{
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", 0)
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
                                .chartYScale(domain: 0...(maxTime))
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
                                .frame(height: 280)
                                
                                HStack(alignment: .center) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                    
                                    Text("Granularity is measured in minutes")
                                        .multilineTextAlignment(.leading)
                                        .font(.caption)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                
                                Spacer()
                                
                            }
                        }
                        .tag(TimePeriod.Week)
                        
                        // Monthly time view
                        VStack {
                            if !monthlyTime.isEmpty {
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "d" // "Tue 19", "Wed 20"
                                    return formatter
                                }()
                                
                                let totalMonthlyTime = monthlyTime.reduce( 0, {$0 + $1.timeMinutes})
                                
                                let maxTime = Double(monthlyTime.max { item1, item2 in
                                    return item2.timeMinutes > item1.timeMinutes
                                }?.timeMinutes ?? 0) / 60.0
                                
                                
                                VStack(alignment: .leading) {
                                    Text("\(minutesToFormattedTime(minutes: totalMonthlyTime))").font(.largeTitle).bold()
                                    Text("Total time last 30 days")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
                                
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedTimeDataForMonthDay {
                                        RuleMark(x: .value("Selected day", selectedTimeDataForMonthDay.date, unit: .day))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedTimeDataForMonthDay.date, format: .dateTime.month(.wide).day().year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    
                                                    Text("\(minutesToFormattedTime(minutes: selectedTimeDataForMonthDay.timeMinutes))")
                                                        .font(.title3)
                                                        .bold()
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(monthlyTime) { timeForDay in
                                        let hours = Double(timeForDay.timeMinutes) / 60.0
                                        
                                        if timeForDay.timeMinutes > 0{
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", timeForDay.animate ? hours : 0 )
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 1))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", timeForDay.animate ? hours : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else {
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForDay.date, unit: .day),
                                                    y: .value("Time", 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                    }
                                    
                                }
                                .chartYScale(domain: 0...(maxTime))
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
                                .frame(height: 280)
                                
                                Spacer()
                            }
                        }
                        .tag(TimePeriod.Month)
                        
                        // Yearly time view
                        VStack {
                            if !yearlyTime.isEmpty {
                                
                                let dateFormatter: DateFormatter = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "MMM" // Mar, Apr, May, etc
                                    return formatter
                                }()
                                
                                let totalYearlyTime = yearlyTime.reduce( 0, {$0 + $1.timeMinutes})
                                
                                let maxTime = Double(yearlyTime.max { item1, item2 in
                                    return item2.timeMinutes > item1.timeMinutes
                                }?.timeMinutes ?? 0) / 60.0
                                
                                
                                VStack(alignment: .leading) {
                                    Text("\(minutesToFormattedTime(minutes: totalYearlyTime))").font(.largeTitle).bold()
                                    Text("Total time this year")
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16 )
                                
                                Chart {
                                    // https://www.youtube.com/watch?v=uloAs9tQIcA&t=276s
                                    if let selectedTimeDataForYearMonth {
                                        RuleMark(x: .value("Selected month", selectedTimeDataForYearMonth.date, unit: .month))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                                VStack(alignment: .leading) {
                                                    Text(selectedTimeDataForYearMonth.date, format: .dateTime.month(.wide).day().year())
                                                        .font(.subheadline)
                                                        .bold()
                                                    
                                                    Text("\(minutesToFormattedTime(minutes: selectedTimeDataForYearMonth.timeMinutes))")
                                                        .font(.title3)
                                                        .bold()
                                                }
                                                .padding(8)
                                                .frame(width: 154, alignment: .leading)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(DARK_GREY))
                                            }
                                    }
                                    
                                    ForEach(yearlyTime) { timeForMonth in
                                        let hours = Double(timeForMonth.timeMinutes) / 60.0
                                        
                                        if timeForMonth.timeMinutes > 0{
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Month", timeForMonth.date, unit: .month),
                                                    y: .value("Time", timeForMonth.animate ? hours : 0)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 1))
                                                .foregroundStyle(LIGHT_GREEN)
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForMonth.date, unit: .month),
                                                    y: .value("Time", timeForMonth.animate ? hours : 0)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(LIGHT_GREEN)
                                            }
                                        }
                                        else {
                                            if isTimeBarChartPresentation {
                                                BarMark (
                                                    x: .value("Month", timeForMonth.date, unit: .month),
                                                    y: .value("Time", 0)
                                                )
                                            } else {
                                                LineMark(
                                                    x: .value("Day", timeForMonth.date, unit: .month),
                                                    y: .value("Time", 0)
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
                                .chartYScale(domain: 0...(maxTime))
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
                Spacer().frame(height: 24)
                
                // Summary statistics sections
                VStack(alignment: .leading, spacing: 24) {
                    
                    Text("Statistics")
                        .font(.title3)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .fontWeight(.semibold)
                    
                    // Total Time
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(LIGHT_GREY))
                        
                        VStack(alignment: .leading) {
                            
                            Text("Total time")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .bold()
                            
                            Text("\(minutesToFormattedTime(minutes: totalTime))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    
                    
                    // Average time per run
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Image(systemName: "waveform")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(LIGHT_GREY))
                        
                        
                        VStack(alignment: .leading) {
                            
                            Text("Avg time")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .bold()
                            
                            Text("\(minutesToFormattedTime(minutes: averageTime)) per run")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                
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
                            get: { !isTimeBarChartPresentation },
                            set: { isTimeBarChartPresentation = !$0 }
                        ))
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
                Text("Time")
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
                isTimeBarChartPresentation = true
            } else {
                generateMonthlyData()
                generateYearlyData()
            }
        }
    }
}

