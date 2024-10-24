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
                
                ZStack {
            
                    TabView(selection: Binding(get: { appState.screen }, set: { newScreen in
                        appState.screen = newScreen
                        showRunView = newScreen == .Run
                        
                    })){
                        
                        Group{
                            
                            DashboardView().tabItem {
                                Image(systemName: "house.fill")
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.white)
                                    .background(.black)
                                    .cornerRadius(26)
                            }
                            .tag(Screen.Dashboard)
                            
                        
                            VStack{}.background(.black)
                                .tabItem {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(NEON)
                                        .background(.black)
                                        .frame(width: 48, height: 48)
                                }.tag(Screen.Run)
                         
                            
                            ProfileView().tabItem {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .background(.black)
                                    .frame(width: 32, height: 32)
                            }
                            .tag(Screen.Profile)
                        }
                        .toolbarColorScheme(.dark, for: .tabBar)
                        .tint(NEON)
                    }
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
        .edgesIgnoringSafeArea([.top, .leading, .bottom, .trailing])
    }
    
}

//
//RunView(showRunView: $showRunView)
//    .transition(.move(edge: .bottom))  // Slide from bottom
//    .animation(.easeInOut(duration: 0.4), value: showRunView)
//    .tabItem {
//        Image(systemName: "plus.circle.fill")
//            .foregroundColor(NEON)
//            .background(.black)
//            .frame(width: 48, height: 48)
//    }
//    .tag(Screen.Run)
