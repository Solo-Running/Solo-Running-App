//
//  Onboarding.swift
//  Solo
//
//  Created by William Kim on 1/27/25.
//

import Foundation
import SwiftUI
import StoreKit
import AlertToast


enum SelectedTab: Int {
    case Welcome = 0, Roam, Data, Start
}

struct OnboardingView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var isSubscribed: Bool = false
    @State var selectedTab: SelectedTab = .Welcome

    @AppStorage("isFirstInApp") var isFirstInApp: Bool = false
    @State private var showIgnoreToast: Bool = false
    
    @Binding var importingData: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView {
                    Group {
                        VStack {
                            Image("SoloLogo")
                                .resizable()
                                .frame(width: 140, height: 140)

                            Text("Solo Running is an app that helps users track and record runs on the go.")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)
                            
                            
                        }
                        .tag(SelectedTab.Welcome)
                        
                        VStack(spacing: 8)  {
                            Image(systemName: "mappin.circle.fill")
                                .tint(.white)
                                .font(.system(size: 64))
                                .padding(.bottom, 16)

                            Text("Roam Anywhere")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Leverage an interactive map to find your favorite locations or save them for later!")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)
                        }
                        .tag(SelectedTab.Roam)

                        
                        VStack(spacing: 8)  {
                            Image(systemName: "checkmark.seal.fill")
                                .tint(.white)
                                .font(.system(size: 64))
                                .padding(.bottom, 16)

                            
                            Text("Secure Data")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("All your information is stored locally on device and never shared with anyone.")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)
                            
                        }
                        .tag(SelectedTab.Data)

                        
                        VStack(spacing: 8)  {
                            
                            Image(systemName: "figure.run")
                                .tint(.white)
                                .font(.system(size: 64))
                                .padding(.bottom, 16)
                            
                            
                            Text("Get Started Today")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Free tier users enjoy \(RUN_LIMIT) runs a month and up to \(PIN_LIMIT) custom pins. Limited run statistics available.")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)

                            Spacer().frame(height: 32)
                            
                            NavigationLink {
                                DashboardView()
                            } label : {
                                HStack {
                                    Text("Continue").foregroundStyle(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(BLUE)
                                .cornerRadius(12)
                                .onTapGesture {
                                    isFirstInApp = false
                                }
                            }
                        }
                        .tag(SelectedTab.Start)

                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(maxHeight: .infinity)
            }
            .toast(isPresenting: $showIgnoreToast, tapToDismiss: true) {
                AlertToast(type: .systemImage("checkmark.circle", Color.green), title: "You will no longer see onboarding content next time.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DashboardView()
                    } label : {
                        Text("Skip")
                            .foregroundStyle(TEXT_LIGHT_GREY)
                            .onTapGesture {
                                isFirstInApp = false
                            }
                    }
                }
                
            }
            .toolbarBackground(.black, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    return OnboardingView(importingData: .constant(false))
}
