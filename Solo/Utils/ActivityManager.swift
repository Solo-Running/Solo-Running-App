//
//  ActivityManager.swift
//  Solo
//
//  Created by William Kim on 10/18/24.
//

import Foundation
import CoreMotion
import Combine
import ActivityKit

struct SoloLiveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var secondsElapsed: Int
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}

class ActivityManager:  ObservableObject {
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    @Published var steps: Int = 0
    @Published var distanceTraveled: Double = 0 // estimated distance in meters
    @Published var averageSpeed: Double = 0 // speed in miles per hour
    @Published var averagePace: Int = 0 // seconds per meter
    
    
    @Published var runStartTime: Date?
    @Published var runEndTime: Date?
    @Published var secondsElapsed = 0
    @Published var formattedDuration: String = ""
    
    
    private var timer: AnyCancellable?
    private var isPaused: Bool = false

    private var activity: Activity<SoloLiveWidgetAttributes>?
    @MainActor @Published private(set) var activityID: String? // unique identifier for started activity

   func startTimer() {
       // Create a timer that fires every second
       timer = Timer.publish(every: 1, on: .main, in: .common)
           .autoconnect()
           .sink { [weak self] _ in
               DispatchQueue.main.async {
                   self?.secondsElapsed += 1
                   self!.formattedDuration = Duration.seconds(self!.secondsElapsed).formatted(
                      .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
                  )
                   self?.updateActivity() // Update activity on every tick
               }
           }
   }
    
    // Function to pause the timer
    func pauseTimer() {
       timer?.cancel()
       timer = nil
       isPaused = true
    }

    // Function to resume the timer
    func resumeTimer() {
       if isPaused {
           startTimer() // Start the timer again from where it left off
           isPaused = false
       }
    }
    
    func stopTimer() {
        // Stop the timer
        timer?.cancel()
        timer = nil
    }
    
    func isTimerPaused() -> Bool {
        return isPaused
    }
  
    
    func clearData() {
        DispatchQueue.main.async {
            self.secondsElapsed = 0
            self.distanceTraveled = 0
            self.steps = 0
            self.averagePace = 0
        }
    }
    
    
    private var isPedometerAvailable: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() &&
        CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
     }
//    
//    func getWeeklySteps() {
//        if isPedometerAvailable {
//            guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
//            else {
//                return
//            }
//            
//            pedometer.queryPedometerData(from: startDate, to: Date()) { (data, error) in
//                guard let data = data, error == nil else {return}
//                
//                DispatchQueue.main.async {
//                    self.steps = data.numberOfSteps.intValue
//                    
//                }
//            }
//        }
//    }
    
    func startTracking() async {
        DispatchQueue.main.async {
            self.runStartTime = Date.now
        }
        startTimer()
        await startActivity()
                
        if runStartTime != nil {
            pedometer.startUpdates(from: self.runStartTime!) { (data, error) in
                if let error = error {
                    print("pedometer start updates  error: \(error)")
                    return
                }
                
                if let data = data {
                    DispatchQueue.main.async {
                        self.steps = data.numberOfSteps.intValue
                        self.distanceTraveled = data.distance?.doubleValue ?? 0
                    }
                }
            }
        } else {
            print("there was an error initializing the start time")
        }
    }
    
    
    func stopTracking() async {
        DispatchQueue.main.async {
            self.runEndTime = Date.now
        }
        stopTimer()
        
        await endActivity()
        
        pedometer.stopUpdates()

        
        if isPedometerAvailable && runStartTime != nil && runEndTime != nil {
            pedometer.queryPedometerData(from: runStartTime!, to: runEndTime!) { (data, error) in
                DispatchQueue.main.async {
//                    self.averagePace = data?.averageActivePace?.intValue ?? 0
                    let distanceInMiles = Double(self.distanceTraveled) / 1609.34
                    // Averaege speed in miles per hour
                    self.averageSpeed = distanceInMiles / (Double(self.secondsElapsed) / 3600)
                    
                    // Average pace in minutes/mile
                    if self.averageSpeed > 0 {
                        self.averagePace = Int((1.0 / self.averageSpeed) * 60)
                    } else {
                        self.averagePace = 0
                    }
                }
            }
        }
    }
    

    
    func startActivity() async {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = SoloLiveWidgetAttributes(timerName: "time elapsed")
            let initialState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0)
            
            activity = try? Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            
            guard let activity = activity else {
                return
            }
            
            await MainActor.run { activityID = activity.id }
            print("ACTIVITY IDENTIFIER:\n\(activity.id)")

        }
    }
    
    func updateActivity()  {
        Task {
            guard let activityID = await activityID,
                  let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }
                let newRandomContentState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: secondsElapsed)
                try await runningActivity.update(using: newRandomContentState)
        }
    }
        
        
    func endActivity() async {
           guard let activityID = await activityID,
                 let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
               return
           }
           let initialContentState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0)

           await runningActivity.end(
               ActivityContent(state: initialContentState, staleDate: Date.distantFuture),
               dismissalPolicy: .immediate
           )
           
           await MainActor.run {
               self.activityID = nil
           }
    }
    
    
}
