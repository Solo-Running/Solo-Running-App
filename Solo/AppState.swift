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


@Observable
final class AppState {
    var hasCredentials: Bool
    var screen: Screen  = .Dashboard
    
    init() {
        hasCredentials = false
    }
}
