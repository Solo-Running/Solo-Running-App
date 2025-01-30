//
//  LaunchManager.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI
enum LaunchScreenStep {
    case initial
    case pending
    case finished
}

/**
  Handles the appearance and dismissal of the LaunchView
 */
@Observable
public class LaunchStateManager {

    var state: LaunchScreenStep = .initial

    @MainActor func dismiss() {
        Task {
            state = .pending

            try? await Task.sleep(for: Duration.seconds(1))

            self.state = .finished
            
            print("dismissed")
        }
    }
}
