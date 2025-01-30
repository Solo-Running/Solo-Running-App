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
    @Query var userData: [UserModel]
    

    
    var body: some View {
        
        ZStack {
            if !subscriptionManager.isSubscribed  {
                // This view also handles susbcription management
                OnboardingView()
            }
            else if !appState.hasCredentials {
                ProvideCredentialsView()
                    .environment(appState)
            }            
            else {
                
                ZStack(alignment: .bottom) {
                   
                    TabView(selection: Binding(get: { appState.screen }, set: { newScreen in
                        appState.screen = newScreen
                        showRunView = newScreen == .Run
                    })){
                        
                        Group {
                            DashboardView().tabItem {
                                Label("Home",systemImage: "house.fill")
                            }
                            .tag(Screen.Dashboard)
                            
                            VStack{}.background(.black)
                                .tabItem {
                                    Label("Add Run",systemImage: "plus.circle.fill")
                                }.tag(Screen.Run)
                            
                            ProfileView().tabItem {
                                Label("Profile",systemImage: "person.circle.fill")
                            }
                            .tag(Screen.Profile)
                        }
                        
                        .toolbarColorScheme(.dark, for: .tabBar)
                        .toolbarBackground(.black, for: .tabBar) 
                    }
                    .tint(.white)
                    .onChange(of: appState.screen, initial: false) { old, new in
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
                                    // dismiss the run view
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
                            
                        }
                    }
                    
                }
            }
        }
        .subscriptionStatusTask(for: "09C0271F") { taskState in
            print("Checking status task")
            if let value = taskState.value {
                print("Task state: \(taskState.value as Any)")
                subscriptionManager.isSubscribed = !value
                    .filter { $0.state != .revoked && $0.state != .expired }
                    .isEmpty
            } else {
                subscriptionManager.isSubscribed = false
            }
            
        }
        .task {
            await subscriptionManager.listenForTransactions()
        }
        .onAppear {
    
            // check for user credentials
            if !userData.isEmpty {
                print("user info is not empty: \(userData)")
                appState.hasCredentials = true
                appState.screen = .Dashboard
            }
            
            if userData.isEmpty {
                print("user data is empty")
            }
            
        }
        .edgesIgnoringSafeArea(.all)
    }
    
}

