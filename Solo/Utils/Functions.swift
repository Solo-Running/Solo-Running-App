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

func convertDateToDateTime(date: Date) -> String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "E d"
    
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mm a"
    
    let dayString = dayFormatter.string(from: date)
    let timeString = timeFormatter.string(from: date)
    
    return "\(dayString), \(timeString)"
    
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


/**
 Converts a range of Dates into a presentable string.
 An example output would be 1:40 PM - 3:00 PM
 */
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
           result = "\(seconds)s"
       }

       return result.isEmpty ? "0s" : result
}


/**
 Converts CLLocationDistance units in meters to feet or miles if the distance is
 at least 1000 ft. An example output would be 500ft or 0.3 mi
 */
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




/**
 Converts a CMPedometer pace units to minutes / mile
 */
func convertPace(secondsPerMeter: Double) -> Double {
    let minutesPerMeter = secondsPerMeter / 60
    let minutesPerMile = minutesPerMeter * 1609.34
    return minutesPerMile
}



func secondsToMinutes(seconds: Int) -> Int {
    return Int(floor(Double(seconds) / 60))
}


/**
 Formats a transaction product id into a presentable string. An example input would be
 solo_yearly_subscription which would become Yearly Subscription
 */
func formatTransactionProductID(_ input: String) -> String {

    let words = input.components(separatedBy: "_")
    
    let formattedWords = words
        .filter { $0.lowercased() != "solo"}
        .map { $0.capitalized }
    
    return formattedWords.joined(separator: " ")
}


/**
 Formats a transaction Date into a date and time string in the form of
 MMM dd. yyy, h:mm a. An example output would be Jan 25, 2025 4:00 PM
 */
func formatTransactionDate(_ date: Date?) -> String {
    if date == nil {
        return "n/a"
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd, yyyy, h:mm a" // Format for "Jan 25, 2025"
    return formatter.string(from: date!)
}


/**
 Formats a transaction price into a currency string. Inputs primarily come from a transaction payload found
 in the subscription manager which can offten appear as a large integer without decimal offsets. Because of this,
 the function has to divide by 1000 to account for this offset and uses a mask to keep the last 2 fraction digits.
 For example a price could appear as 8990 which would become $8.99. Otherwise if the price is 0, it becomes $0.00
 */
func formatTransactionPrice(_ price: Int) -> String {
    // Convert to Double for decimal formatting
    let amount = Double(price) / 1000.0
    
    // Create a NumberFormatter to format as currency
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD" // Change to your desired currency code
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    
    // Format the amount
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

