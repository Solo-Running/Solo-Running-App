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


/**
  The emitted data that Live Widgets use to display to the user about an active run session
 */
struct SoloLiveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var secondsElapsed: Int
        var steps: Int
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}


/**
  Manages the monitoring of time, Core Motion  data, and execution of any Live Activities for an active run session.
 */
class ActivityManager: NSObject, ObservableObject {
    
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    @Published var isMotionAuthorized: Bool = false
    
    @Published var steps: Int = 0
    @Published var distanceTraveled: Double = 0 // estimated distance in meters
    @Published var averageSpeed: Double = 0     // speed in miles per hour
    @Published var averagePace: Int = 0         // seconds per meter
    
    @Published var runStartTime: Date?
    @Published var runEndTime: Date?
    @Published var secondsElapsed = 0
    @Published var formattedDuration: String = ""
    
    private var timer: AnyCancellable?
    private var isPaused: Bool = false

    private var activity: Activity<SoloLiveWidgetAttributes>?
    @MainActor @Published private(set) var activityID: String? // unique identifier for started activity

    
    override init()  {
        super.init()    
       
        let today = Date()

        activityManager.queryActivityStarting(from: today, to: today, to: OperationQueue.main, withHandler: { (activities: [CMMotionActivity]?, error: Error?) -> () in
           if error != nil {
               let errorCode = (error! as NSError).code
               if errorCode == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                   print("Activity manager not authorized")
                   self.setMotionAuthorization(value: false)
               }
           } else {
               print("Activity manager authorized")
               self.setMotionAuthorization(value: true)
           }
        })
    }
    
    
    private var isPedometerAvailable: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() &&
        CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
     }
    
    func setMotionAuthorization(value: Bool) {
        DispatchQueue.main.async {
            self.isMotionAuthorized = value
        }
    }
        
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
                   self?.updateLiveActivity()
               }
           }
   }
    
    func pauseTimer() {
       timer?.cancel()
       timer = nil
       isPaused = true
    }

    func resumeTimer() {
       if isPaused {
           startTimer()
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
        
    
    // This listens for changes in pedometer authorizations
    func checkAuthorization() {
        switch CMPedometer.authorizationStatus() {
            
        case .notDetermined:
            print("core motion authorizations not determined")
            setMotionAuthorization(value: false)
        case .denied:
            print("core motion authorization denied")
            setMotionAuthorization(value: false)
        case .authorized:
            print("core motion authorized")
            setMotionAuthorization(value: true)
        default:
            print("core motion authorized by default")
            setMotionAuthorization(value: true)
        }
    }
    
    
    func startMotionAndActivityTracking() async {
        
        // We should always start the run regardless of live activity permissions
        await startLiveActivity { _ in

            if self.runStartTime != nil && self.isPedometerAvailable {
                self.startTimer()
                
                // The pedometer will track distance and steps. I ignored CMPedometer pace for now since it's a bit inaccurate
                self.pedometer.startUpdates(from: self.runStartTime!) { (data, error) in
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
            }
        }
    }
    

        
    // Prepare to launch the run session only if the user had previously authorized the use of the pedometer
    func beginRunSession() async {
        
        DispatchQueue.main.async {
            self.runStartTime = Date.now
        }
        
        if CMPedometer.authorizationStatus() == .authorized {
            await startMotionAndActivityTracking()
        }
        else {
            // MMaybe show an error to the user that core motion needs to be enabled
            setMotionAuthorization(value: false)
        }
    }

        
    
    // Stop the timer and capture the user's final statistics
    func endRunSession() async {
        
        DispatchQueue.main.async {
            self.runEndTime = Date.now
        }
        
        stopTimer()
        await endLiveActivity()
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
    
    
    func startLiveActivity(completion: @escaping (Bool) -> Void) async {
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = SoloLiveWidgetAttributes(timerName: "time elapsed")
            let initialState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0, steps: 0)
            
            activity = try? Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(28800))
            )
            
            guard let activity = activity else {
                return completion(false)
            }
            
            await MainActor.run { activityID = activity.id }
            print("ACTIVITY IDENTIFIER:\n\(activity.id)")
            return completion(true)
        }
    }
    
    
    func updateLiveActivity()  {
        Task {
            guard let activityID = await activityID,
                  let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }
            let newRandomContentState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: secondsElapsed, steps: steps)
            await runningActivity.update(using: newRandomContentState)
        }
    }
    
    
    func endLiveActivity() async {
        guard let activityID = await activityID,
              let runningActivity = Activity<SoloLiveWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
            return
        }
        let initialContentState = SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0, steps: 0)
        
        await runningActivity.end(
            ActivityContent(state: initialContentState, staleDate: Date.distantFuture),
            dismissalPolicy: .immediate
        )
        
        await MainActor.run {
            self.activityID = nil
        }
    }
}
    
