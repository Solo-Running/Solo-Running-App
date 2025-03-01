//
//  SubscriptionsManager.swift
//  Solo
//
//  Created by William Kim on 1/27/25.
//

import Foundation
import StoreKit

/**
 Helpful Resources:
 https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode#Disable-StoreKit-Testing-in-Xcode
 https://medium.com/@mafz/how-to-enable-sandbox-in-app-purchases-for-ios-apps-71215c250595
 */


@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    
    @Published var productIds: [Product.ID] = ["monthly_subscription", "yearly_subscription"]
    private var groupID =  "21636260"
    
    @Published var isSubscribed: Bool = false
    
    @Published var currentTransaction: Transaction?
    @Published var transactionPayload: Data?                                    // used to get the price and offer discount type information
    @Published var currentRenewalInfo: Product.SubscriptionInfo.RenewalInfo?    // used to determine if the current subscription will expire or renew

    @Published var recentPurchases: [Transaction] = []
    @Published var isLoadingPurchases: Bool = true
    @Published var isLoadingEntitlement: Bool = true
    
    override init() {
        super.init()
        Task {
            await getSubscriptionStatusAndEntitlement()
        }
    }

    // Listen for storekit updates
    func listenForTransactions() async {
        for await verificationResult in Transaction.updates {
            switch verificationResult {
            case .verified(let transaction):
                await handleTransaction(transaction)
            case .unverified(_,_):
                print("not verified")
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
       switch transaction.revocationDate {
       case .some(_):
           print("Transaction revoked: \(transaction.id)")
        
       case .none:
           print("Transaction successful: \(transaction.id)")
                
           // Finish transaction to remove it from queue
           await transaction.finish()
       }
   }
    
    // Fetches the user's purchase history of past subscriptions
    func getRecentPurchases() async {
        self.isLoadingPurchases = true
        self.recentPurchases.removeAll()
        
        for await verificationResult in Transaction.all {
            switch verificationResult {
            case .verified(let transaction):
                if productIds.contains(transaction.productID) {
                    recentPurchases.append(transaction)
                }
            case .unverified(_, _):
                print("not verified")
            }
        }
        
        self.isLoadingPurchases = false
    }
    
    

    func getSubscriptionStatusAndEntitlement() async {
        self.isLoadingEntitlement = true
        
        // Iterate through the user's purchased products.
        for await result in Transaction.currentEntitlements {
            print("verification Result: \(result)")
           
            guard case .verified(let transaction) = result else {
                continue
            }
                        
            // Get the current subscription data
//            if productIds.contains(transaction.productID) {
//                currentTransaction = transaction
//                transactionPayload = result.payloadData
//            }
//            
            // Get the renewal information for the current subscription
            do {
                let products = try await Product.products(for: [transaction.productID])
                for product in products {
                    do {
                        let productSubInfo = try await product.subscription?.status
                        
                        for subInfo in productSubInfo! {
                            if subInfo.state == .subscribed {
                                
                                currentTransaction = transaction
                                transactionPayload = result.payloadData
                                
                                switch subInfo.renewalInfo {
                                case .verified(let prodStatus):
                                    if (prodStatus.currentProductID == transaction.productID) {
                                        currentRenewalInfo = prodStatus
                                    }
                                    break
                                default:
                                    break
                                }}
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        self.isLoadingEntitlement = false

    }
}


// if(prodStatus.autoRenewPreference != nil) && (prodStatus.autoRenewPreference != transaction.productID){
//     nextRenewalInfo = prodStatus
// }
