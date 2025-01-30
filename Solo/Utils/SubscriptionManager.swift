//
//  SubscriptionsManager.swift
//  Solo
//
//  Created by William Kim on 1/27/25.
//

import Foundation
import StoreKit


@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    
    @Published var productIds: [String] = ["solo_monthly_subscription", "solo_yearly_subscription"]

    @Published var isSubscribed: Bool = false
    
    @Published var currentTransaction: Transaction?
    @Published var transactionPayload: Data? // used to get the price and offer discount type information
    @Published var currentRenewalInfo: Product.SubscriptionInfo.RenewalInfo? // used to determine if the current subscription will expire or renew
    @Published var nextRenewalInfo: Product.SubscriptionInfo.RenewalInfo?

    @Published var recentPurchases: [Transaction] = []
    @Published var isLoadingPurchases: Bool = false

    
    override init() {
        super.init()
        Task {
            await getSubscriptionStatusAndEntitlement()
            await getRecentPurchases()
        }
    }

    
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
           // Handle refund/revocation if needed
           
       case .none:
           print("Transaction successful: \(transaction.id)")
           // Unlock content here
           isSubscribed = true
           
           // Finish transaction to remove it from queue
           await transaction.finish()
       }
   }
    
    func getRecentPurchases() async {
        isLoadingPurchases = true
        recentPurchases.removeAll()
        
        for await verificationResult in Transaction.all {
            switch verificationResult {
            case .verified(let transaction):
                if productIds.contains(transaction.productID) {
                    // Create a Purchase object with a unique ID for each transaction
                    recentPurchases.append(transaction)
                }
            case .unverified(_, _):
                print("not verified")
            }
        }
        // print("Purchases \(recentPurchases)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingPurchases = false
        }
    }
    
    
    func getSubscriptionStatusAndEntitlement() async {
                        
        // Iterate through the user's purchased products.
        for await result in Transaction.currentEntitlements {
            print("verification Result: \(result)")
           
            // Could be a current active subscription and/or one that will start in
            // a later cycle. This might happen if a user changes from an active subscription
            // in which case, the next plan starts after the current expiration date
            guard case .verified(let transaction) = result else {
                continue
            }
                        
            if productIds.contains(transaction.productID) {
                await transaction.finish()
                currentTransaction = transaction
                transactionPayload = result.payloadData
            }
            
            
            // Get the renewal information for the current active subscription or any next different subscriptions
            do {
                let products = try await Product.products(for: [transaction.productID])
                for product in products {
                    do {
                        let productSubInfo = try await product.subscription?.status
                        for subInfo in productSubInfo! {
                            switch subInfo.renewalInfo {
                            case .verified(let prodStatus):
                                if (prodStatus.currentProductID == transaction.productID) {
                                    currentRenewalInfo = prodStatus
                                    NSLog("Product is the same")
                                } 
                                
                                if(prodStatus.autoRenewPreference != nil) && (prodStatus.autoRenewPreference != transaction.productID){
                                    nextRenewalInfo = prodStatus
                                }
                                else {
//                                    NSLog("Product is different : \(String(describing: prodStatus.autoRenewPreference))")
                                }
                                break
                            default:
                                break
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}
