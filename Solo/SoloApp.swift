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
    @StateObject var subscriptionManager = SubscriptionManager()
    
    // Initialize the model container for persistent storage operations
    var modelContainer: ModelContainer = {
        let schema = Schema([
            UserModel.self,
            MTPlacemark.self,
            Run.self
        ])
        
        // Handle changes in iCloud syncing
        // https://www.youtube.com/watch?v=DlSPD9dl8Bc
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        let modelConfigurationOff = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: ModelConfiguration.CloudKitDatabase.none)
        
        let iCloudToken = FileManager.default.ubiquityIdentityToken
        if iCloudToken == nil {
            do {
                return try ModelContainer(for: schema, configurations: [modelConfigurationOff])
            } catch {
                fatalError("Could not create model container: \(error)")
            }
            
        } 
        else {
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
      
    }()
    

    var body: some Scene {
        WindowGroup {
            
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
            .environmentObject(subscriptionManager)
            .modelContainer(modelContainer)
            .onAppear {
                // set a timer for splash screen duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        launchManager.dismiss()
                    }
                }
            }
        }
    }
}

