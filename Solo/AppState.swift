//
//  AppState.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//

import Foundation


enum Screen: Int {
    case Dashboard = 0, Run, Profile
}

enum TimePeriod: Int {
    case Week = 0, Month, Year
}

@Observable
final class AppState {
    var hasCredentials: Bool
    var screen: Screen  = .Dashboard
    var isLoadingCloudData: Bool
    
    init() {
        hasCredentials = false
        isLoadingCloudData = false
    }
}







