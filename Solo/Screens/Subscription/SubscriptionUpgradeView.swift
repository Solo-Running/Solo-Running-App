//
//  SubscriptionStoreView.swift
//  Solo
//
//  Created by William Kim on 1/29/25.
//

import Foundation
import SwiftUI
import StoreKit


/**
 Renders a SubscriptionStoreView for onboarding users or users that don't have an active subscription.
 */
struct SubscriptionUpgradeView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        SubscriptionStoreView(productIDs: subscriptionManager.productIds){
            VStack {
                Image("SoloLogo")
                    .resizable()
                    .frame(width: 48, height: 48)
               
                Text("Unlock Full Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
                
                Text("Feeling adventurous? Pro members can unlock Solo with unlimited runs, custom pins, and comprehensive statistics.")
                    .frame(maxWidth: 224, alignment: .center)
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
                subscriptionManager.isSubscribed = true
                
                Task {
                    await subscriptionManager.getSubscriptionStatusAndEntitlement()
                }
                
                /*
                 * StoreKit automatically keeps up to date transaction information and subscription status available to your app. When users reinstall your app or download it on a new device,
                 * the app automaticallyall transactions available to it upon initial launch. There’s no need for users to ask your app to restore transactions — your app can
                 * immediately get the current entitlements using currentEntitlements and transaction history using all.
                 */
              
                
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

    

