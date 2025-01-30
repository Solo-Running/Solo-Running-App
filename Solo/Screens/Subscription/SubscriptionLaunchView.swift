//
//  SubscriptionStoreView.swift
//  Solo
//
//  Created by William Kim on 1/29/25.
//

import Foundation
import SwiftUI
import StoreKit

struct SubscriptionLaunchView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        SubscriptionStoreView(groupID: "09C0271F", visibleRelationships: .all){
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
                subscriptionManager.isSubscribed = true
                
                Task {
                    await subscriptionManager.getSubscriptionStatusAndEntitlement()
                }
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

    

