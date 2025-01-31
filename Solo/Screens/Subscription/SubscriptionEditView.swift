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
    let isUpgraded: Bool
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
        if let transaction = subscriptionManager.currentTransaction {
            
            VStack(alignment: .leading, spacing: 24) {
                
                Spacer().frame(height: 16)
                
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
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Recent Purchases")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                  
                    Text("Subscriptions that begin after an expiring purchase won't appear here.")
                        .font(.subheadline)
                        .foregroundStyle(TEXT_LIGHT_GREY)
                }
               
                if !subscriptionManager.recentPurchases.isEmpty {
                    
                    if subscriptionManager.isLoadingPurchases {
                        VStack(alignment: .center) {
                            Spacer()
                            ProgressView()
                                .tint(TEXT_LIGHT_GREY)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                    }
                    else {
                        let sortedPurchases = subscriptionManager.recentPurchases.sorted { $0.purchaseDate > $1.purchaseDate }
                        
                        List(sortedPurchases, id: \.id) { purchase in
                            VStack(alignment: .leading) {
                                
                                Text(formatTransactionProductID(purchase.productID))
                                    .onTapGesture {
                                        print(formatTransactionDate(purchase.purchaseDate))
                                        presentRefundRequest(transaction: purchase)
                                    }
                                HStack(alignment: .center) {
                                    Text("Purchased \(formatTransactionDate(purchase.purchaseDate))")
                                        .font(.caption)
                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                    Spacer()
                                    
                                    if purchase.revocationDate !=  nil{
                                        Text("Refunded")
                                            .font(.caption)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                    
                                    if let transaction = subscriptionManager.currentTransaction, (transaction.productID == purchase.productID) && (purchase.revocationDate == nil) {
                                        Text("Current")
                                            .font(.caption)
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .preferredColorScheme(.dark)
            .manageSubscriptionsSheet(isPresented: $isPresentingCancellationSheet)
            .onAppear {
                Task {
                    await subscriptionManager.getRecentPurchases()
                    await subscriptionManager.getSubscriptionStatusAndEntitlement()
                    if subscriptionManager.transactionPayload != nil {
                        do {
                            payload = try JSONDecoder().decode(Payload.self, from: subscriptionManager.transactionPayload!)
                        } catch {
                            print("Failed to decode JSON: \(error)")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await subscriptionManager.getRecentPurchases()
                            await subscriptionManager.getSubscriptionStatusAndEntitlement()
                        }
                    } label: {
                        Text("Refresh").font(.subheadline).foregroundStyle(TEXT_LIGHT_GREY).background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY).padding())
                    }
                }
            }
            
            Spacer()
        }
    }
}
