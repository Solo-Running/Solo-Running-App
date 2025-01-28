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
    case Welcome = 0, Roam, Data, Spotify, Start
}

struct OnboardingView: View {
    
    @State private var isSubscribed: Bool = false
    @State var selectedTab: SelectedTab = .Welcome

    @AppStorage("ignoreOnboarding") var ignoreOnboarding: Bool = false
    @State private var showIgnoreToast: Bool = false
  
    var body: some View {
        NavigationStack {
            VStack {
                TabView {
                    Group {
                        VStack(spacing: 8) {
                            Image("SoloLogo")
                                .tint(.white)
                                .frame(width: 64, height: 64)
                                .padding(.bottom, 16)

                            Text("Welcome")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
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
                            
                            Text("All your information is stored locally on device and naver shared with anyone.")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)
                            
                        }
                        .tag(SelectedTab.Data)

                        
                        VStack(spacing: 8)  {
                            Image(systemName: "music.note")
                                .tint(.white)
                                .font(.system(size: 64))
                                .padding(.bottom, 16)

                            Text("Music In Your Hands")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Play Spotify directly from in the app while running!")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)
                            
                        }
                        .tag(SelectedTab.Spotify)
                        
                        
                        VStack(spacing: 8)  {
                            
                            Image(systemName: "figure.run")
                                .tint(.white)
                                .font(.system(size: 64))
                                .padding(.bottom, 16)
                            
                            
                            Text("Get Started Today")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Join the community with a free 7 day trial. Cancel anytime.")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .multilineTextAlignment(.center)

                            
                            Spacer().frame(height: 32)
                            Button {
                                // Nothing
                            } label: {
                                NavigationLink {
                                    // if user has subscription, go to dashboard
                                    if isSubscribed {
                                        DashboardView()
                                    } else {
                                        SubscriptionLaunchView()
                                    }
                                } label : {
                                    HStack {
                                        Text("Continue").foregroundStyle(.white)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(BLUE)
                                    .cornerRadius(12)
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
                AlertToast(type: .systemImage("checkmark.circle", Color.green), title: "SYou will no longer see onboarding content next time.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        if isSubscribed {
                            DashboardView()
                        } else {
                            SubscriptionLaunchView()
                        }
                    } label : {
                        Text("Skip")
                            .foregroundStyle(TEXT_LIGHT_GREY)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

struct SubscriptionLaunchView: View {
    @EnvironmentObject var subscriptionsManager: SubscriptionsManager
    
    
    var body: some View {
        SubscriptionStoreView(groupID: "09C0271F"){
            VStack {
                Image("SoloLogo")
                    .resizable()
                    .frame(width: 48, height: 48)
               
                Text("Unlock Full Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                
                Text("Experience Solo with unlimited access. Your support keeps this platform thriving!")
                    .frame(maxWidth: 200, alignment: .center)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .onInAppPurchaseStart { product in
            print("User has started buying \(product.id)")
        }
        .onInAppPurchaseCompletion { product, result in
            if case .success(.success(let transaction)) = result {
                print("Purchased successfully: \(transaction.signedDate)")
                subscriptionsManager.isSubscribed = true
            } else {
                print("Something else happened")
            }
        }
        .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .subscriptionStoreButtonLabel(.action)
        .toolbar(.hidden)
        .tint(BLUE)
        
    }
}

    

