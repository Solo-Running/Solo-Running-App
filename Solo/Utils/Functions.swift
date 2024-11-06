//
//  Functions.swift
//  Solo
//
//  Created by William Kim on 10/26/24.
//

import Foundation
import MapKit

// Formats a Date to friendly format into 1:13am
func convertDateToString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"  // 'h' is for hour in 12-hour format, 'a' is for AM/PM

    let timeString = formatter.string(from: date)
    return timeString
}


func getDayAndTimeRange(startDate: Date, endDate: Date) -> String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "E d"  // 'h' is for hour in 12-hour format, 'a' is for AM/PM
    
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mm a"  // 'h' is for hour in 12-hour format, 'a' is for AM/PM
    
    let dayString = dayFormatter.string(from: startDate)
    let startTimeString = timeFormatter.string(from: startDate)
    let endTimeString = timeFormatter.string(from: endDate)
    
    return  "\(dayString), \(startTimeString)-\(endTimeString)"

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

// Helper function to format route step distances to user friendly format
func convertMetersToString(distance: CLLocationDistance) -> String {
    // Constants for conversion
    let metersInMile = 1609.34
    let metersInFoot = 0.3048
    
    // If distance is at least 1000ft
    if distance.magnitude >= 304.8 {
        // Convert meters to miles
        let miles = distance.magnitude / metersInMile
        return String(format: "%.1f mi", miles)
    } else {
        // Convert meters to feet
        let feet = distance.magnitude / metersInFoot
        return String(format: "%.0f ft", feet)
    }
}




// Converts CMPedometer Pace Units to Minutes/Mile
func convertPace(secondsPerMeter: Double) -> Double {
    let minutesPerMeter = secondsPerMeter / 60
    let minutesPerMile = minutesPerMeter * 1609.34
    return minutesPerMile
}



func secondsToMinutes(seconds: Int) -> Int {
    
    return Int(floor(Double(seconds) / 60))
}


