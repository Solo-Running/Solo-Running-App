//
//  MainView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//

import Foundation
import SwiftUI
import SwiftData
import StoreKit
import CoreData
import AlertToast

/**
 The primary access point  to the app tapphat handles overhead logic for utility managers and background tasks
 including subscription status tasks, user navigation, user profiile, and the app state.
 */
struct MainView: View {
    
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State var selectedScreen: Screen = .Dashboard
    @State var oldSelectedScreen: Screen = .Dashboard
    @State private var showRunView: Bool = false  // Control visibility of RunView
    @State private var permissionsSheetDetents: Set<PresentationDetent> =  [.large]
    
    @State var publisher = NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
    @State var importingData: Bool = false
    @State var showUserNullAlert: Bool = false
    // Determines if the user needs to onboard
    @AppStorage("isFirstInApp") var isFirstInApp: Bool = true

    @Query var userData: [User]
    var user: User? {userData.first}
    

    var body: some View {
        
        ZStack {
            if isFirstInApp {
                // This view also handles susbcription management
                OnboardingView(importingData: $importingData)
            } 
            else {
                ZStack(alignment: .bottom) {
                   
                    TabView(selection: Binding(get: { appState.screen }, set: { newScreen in
                        appState.screen = newScreen
                        if user != nil {
                            showRunView = newScreen == .Run
                        }
                        else if user == nil {
                            if newScreen == .Run {
                                showUserNullAlert = true
                            }
                        }
                    })){
                        Group {
                            DashboardView().tabItem {
                                Label("Home",systemImage: "house.fill")
                            }
                            .tag(Screen.Dashboard)

                            // Attach an empty view since the Run Screen appears as a full cover on top
                            VStack(alignment: .center) {
                                Spacer()
                                Text("Set up your profile in order to track your run streaks!")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 140)
                                Spacer()
                            }
                            .background(.black)
                            .tabItem {
                                Label("Add Run",systemImage: "plus.circle.fill")
                            }
                            .tag(Screen.Run)
                            
                            
                            ProfileView().tabItem {
                                Label("Profile",systemImage: "person.circle.fill")
                            }
                            .tag(Screen.Profile)

                        }
                        .toolbarColorScheme(.dark, for: .tabBar)
                        .toolbarBackground(.black, for: .tabBar)
                    }
                    .sensoryFeedback(.impact, trigger: appState.screen)
                  
                    .tint(.white)
                    .onChange(of: appState.screen, initial: false) { old, new in
                        // Try to remember what screen we were looking at previously
                        if appState.screen == .Run {
                            appState.screen = old
                        }
                    }
                    .fullScreenCover(isPresented: $showRunView, onDismiss: {
                        self.selectedScreen = self.oldSelectedScreen
                    }) {
                        
                        if !activityManager.isMotionAuthorized || !locationManager.isAuthorized {
                            VStack(alignment: .leading) {
                                
                                Button {
                                    showRunView = false
                                } label: {
                                    ZStack {
                                        Circle()
                                            .frame(width: 32, height: 32)
                                            .foregroundStyle(.white)
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.black)
                                            .frame(width: 16, height: 16)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding([.leading], 16)
                                
                                PermissionsView()
                            }
                            .background(DARK_GREY)
                        }
                        else {
                            RunView(showRunView: $showRunView)
                                .onAppear {
                                    Task {
                                        // We want to make sure the user accesses appropriate features
                                        // based on their subscription status
                                        await subscriptionManager.getSubscriptionStatusAndEntitlement()
                                    }
                                }
                        }
                    }
                }
                .toast(isPresenting: $showUserNullAlert, tapToDismiss: true) {
                    AlertToast(type: .systemImage("person", Color.white), title: "Set up your profile first.")
                }
            }
        }
    
        .onReceive(publisher) { notification in
            if let userInfo = notification.userInfo {
               if let event = userInfo["event"] as? NSPersistentCloudKitContainer.Event {
                   if event.type == .import {
                       importingData = true
                       appState.isLoadingCloudData = true
                       print("Importing cloud data")
                   }
                   else {
                       importingData = false
                       appState.isLoadingCloudData = false
                       print("Not importing cloud data")
                   }
                }
             }
        }
        .task {
            await subscriptionManager.listenForTransactions()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
}


// https://stackoverflow.com/questions/78845389/storekit-2-how-to-use-subscriptionstatustask-modifier-to-know-which-subscripti
// https://imgur.com/wrhNpbo
//
// If using test flight, auto renewable susbcriptions will expire after 12 renewals. See the link below
// https://www.revenuecat.com/blog/engineering/the-ultimate-guide-to-subscription-testing-on-ios/
//        .subscriptionStatusTask(for: "21636260") { taskState in
//            print("Checking status task")
//            if let value = taskState.value {
//                print("Task state: \(taskState.value as Any)")
//                subscriptionManager.isSubscribed = !value
//                    .filter { $0.state != .revoked && $0.state != .expired  }
//                    .isEmpty
//            } else {
//                subscriptionManager.isSubscribed = false
//            }
//        }
