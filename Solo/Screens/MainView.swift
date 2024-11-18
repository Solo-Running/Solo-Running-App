//
//  MainView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//

import Foundation
import SwiftUI
import SwiftData

struct MainView: View {
    
    @Environment(AppState.self) var appState
    @State var selectedScreen: Screen = .Dashboard
    @State var oldSelectedScreen: Screen = .Dashboard

    @State private var showRunView: Bool = false  // Control visibility of RunView

    
    @Environment(\.modelContext) private var modelContext
    @Query var userData: [UserModel]

    
    var body: some View {
        
        ZStack {
            if !appState.hasCredentials {
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
                        RunView(showRunView: $showRunView)
                    }
                    
                }
            }
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

