//
//  SubscriptionEditView.swift
//  Solo
//
//  Created by William Kim on 1/29/25.
//

import Foundation
import SwiftUI
import StoreKit

/**
 Provides fine tuned access to  a user's active susbscription, renewal information, and past purchases.
 Comes with the ability to refund purchases as well althouugh this action will disable access to the app
 once completed successfully.
 */
struct SubscriptionEditView: View {
    
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isPresentingCancellationSheet: Bool = false
    @State private var payload: Payload?
    @State private var refundRequestTransactionID: UInt64 = 0
    @State private var isPresentingRefundRequestSheet: Bool = false
    @State private var isPresentingUpgradeSheet: Bool = false
    
    func refetchEntitlement() async {
        await subscriptionManager.getSubscriptionStatusAndEntitlement()
        if subscriptionManager.transactionPayload != nil {
            do {
                payload = try JSONDecoder().decode(Payload.self, from: subscriptionManager.transactionPayload!)
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }
    }
    
    func presentRefundRequest(transaction: StoreKit.Transaction) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("No active scene found")
            return
        }
        Task {
            do {
                try await transaction.beginRefundRequest(in: scene)
                print("Refund request sheet presented successfully")
            } catch {
                print("Error presenting refund request: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 24) {
                
                Spacer().frame(height: 16)
                
                
                if let transaction = subscriptionManager.currentEntitlement, !subscriptionManager.hasSubscriptionExpired(){
                    VStack(alignment: .leading) {
                        Text("Subscription").foregroundStyle(.white).fontWeight(.semibold)
                        HStack {
                            Text(formatTransactionProductID(transaction.productID))
                            if (payload?.offerDiscountType != nil) && (Date() < transaction.expirationDate! ) {
                                Text("- \(formatTransactionProductID(payload!.offerDiscountType!))")
                            }
                        }
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("Description").foregroundStyle(.white).fontWeight(.semibold)
                        Text("Unlimited runs and custom pins.")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("Plan Price").foregroundStyle(.white).fontWeight(.semibold)
                        if payload?.price != nil {
                            Text("\(formatTransactionPrice(payload!.price))").foregroundStyle(TEXT_LIGHT_GREY)
                        }
                        else {
                            Text("").foregroundStyle(TEXT_LIGHT_GREY)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        if let renewalInfo = subscriptionManager.currentRenewalInfo {
                            Text(renewalInfo.willAutoRenew ? "Renews" : "Expires").foregroundStyle(.white).fontWeight(.semibold)
                        }
                        
                        Text(formatTransactionDate(transaction.expirationDate)).foregroundStyle(TEXT_LIGHT_GREY)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        isPresentingCancellationSheet = true
                    } label: {
                        Text("Manage your subscription")
                            .foregroundStyle(BLUE)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        presentRefundRequest(transaction: transaction)
                    } label: {
                        Text("Request refund")
                            .foregroundStyle(RED)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                } else {
                    VStack(alignment: .leading) {
                        Text("Subscription").foregroundStyle(.white).fontWeight(.semibold)
                        Text("Free Tier")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("Description").foregroundStyle(.white).fontWeight(.semibold)
                        Text("\(RUN_LIMIT) runs per month. Up to \(PIN_LIMIT) total custom pins.")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    
                    NavigationLink {
                        RecentPurchasesView()
                    } label: {
                        HStack(alignment: .center) {
                            
                            VStack(alignment: .leading){
                                Text("All Purchases")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("View all past subscription transactions.")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .frame(width: 24, height: 24)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    }
                }
                
                if subscriptionManager.hasSubscriptionExpired() {
                    Button {
                        isPresentingUpgradeSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .center) {
                                Text("Join Pro")
                                    .font(.title3)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Text("Upgrade")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Capsule().fill(LIGHT_BLUE))
                                }
                            
                                Text("Yearly or monthly subscription.")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(LIGHT_BLUE)
                            }
                            .frame(maxWidth: .infinity, alignment: Alignment.leading)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(BLUE))
                }
                
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .preferredColorScheme(.dark)
            .manageSubscriptionsSheet(isPresented: $isPresentingCancellationSheet)
            
            Spacer()
            
        }
        .onAppear {
            Task {
                await refetchEntitlement()
            }
        }
        .refreshable {
            await refetchEntitlement()
        }
        .fullScreenCover(isPresented: $isPresentingUpgradeSheet, onDismiss: {
            Task {
                await refetchEntitlement()
            }
        }) {
            SubscriptionUpgradeView()
        }
    }
    
}

