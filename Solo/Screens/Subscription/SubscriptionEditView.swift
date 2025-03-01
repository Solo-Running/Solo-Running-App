//
//  SubscriptionEditView.swift
//  Solo
//
//  Created by William Kim on 1/29/25.
//

import Foundation
import SwiftUI
import StoreKit

struct Payload: Codable {
    let bundleId: String
    let currency: String
    let deviceVerification: String
    let deviceVerificationNonce: String
    let environment: String
    let expiresDate: Int
    let inAppOwnershipType: String
    let isUpgraded: Bool?
    let offerDiscountType: String?
    let offerType: Int?
    let originalPurchaseDate: Int
    let originalTransactionId: String
    let price: Int
    let productId: String
    let purchaseDate: Int
    let quantity: Int
    let signedDate: Int
    let storefront: String
    let storefrontId: String
    let subscriptionGroupIdentifier: String
    let transactionId: String
    let transactionReason: String
    let type: String
    let webOrderLineItemId: String
}

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
    
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 24) {
                
                Spacer().frame(height: 16)
                
                
                if let transaction = subscriptionManager.currentTransaction {
                    VStack(alignment: .leading) {
                        Text("Susbcription").foregroundStyle(.white).fontWeight(.semibold)
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
                }
                
                Button {
                    isPresentingCancellationSheet = true
                } label: {
                    Text("Manage your subscription")
                        .foregroundStyle(BLUE)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
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
                
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .preferredColorScheme(.dark)
            .manageSubscriptionsSheet(isPresented: $isPresentingCancellationSheet)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await subscriptionManager.getSubscriptionStatusAndEntitlement()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(TEXT_LIGHT_GREY)
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
        }
        .onAppear {
            Task {
                await subscriptionManager.getSubscriptionStatusAndEntitlement()
                if subscriptionManager.transactionPayload != nil {
                    do {
                        payload = try JSONDecoder().decode(Payload.self, from: subscriptionManager.transactionPayload!)
                    } catch {
                        print("Failed to decode JSON: \(error)")
                    }
                }
                
                print(payload)
            }
        }
        .refreshable {
            await subscriptionManager.getSubscriptionStatusAndEntitlement()
        }
    }
    
}

