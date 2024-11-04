//
//  SoloApp.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import SwiftUI
import SwiftData


@main
struct SoloApp: App {
    
    @State var appState = AppState()
    @State var isLoading = false
    @State var launchManager = LaunchStateManager()
    @StateObject var locationManager = LocationManager()
    @StateObject var activityManager = ActivityManager()
    
    // Initialize the model container for persistent storage operations
    var modelContainer: ModelContainer = {
        let schema = Schema([
            UserModel.self,
            Run.self
        ])
        
        // tell swift data to persist data to disk instead of memory
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    

    var body: some Scene {
        WindowGroup {
            
            if (locationManager.isAuthorized) {
                
                ZStack{
                    
                    // Show a splash screen on first app launch
                    LaunchView()
                        .opacity(launchManager.state != .finished ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: launchManager.state) // Animate opacity when state changes

                
                    // When splash screen animation finishes show the main view
                    MainView()
                        .environment(appState)
                        .opacity(launchManager.state == .finished ? 1: 0)
                        .animation(.easeOut(duration: 0.2), value: launchManager.state) // Animate opacity when state changes

                }
                .environment(launchManager)
                .environmentObject(locationManager)
                .environmentObject(activityManager)
                .modelContainer(for: [Run.self, UserModel.self], inMemory: false)
                .onAppear {
                    
                    // set a timer for splash screen duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            launchManager.dismiss()
                        }
                    }
                }
            } else {
                // Location denied view
            }
        }
       
        
    }
}

//
//    @MainActor
//    private func initializeRuns() async {
//        do {
//            print("fetching data")
//            let fetchedRuns = try modelContainer.mainContext.fetch(FetchDescriptor<Run>(sortBy: [SortDescriptor(\.postedDate)]))
//            runData.runs = fetchedRuns // Update the state with the fetched data
//            self.launchManager.dismiss()
//        } catch {
//            print("Failed to fetch runs: \(error)")
//        }
//    }
