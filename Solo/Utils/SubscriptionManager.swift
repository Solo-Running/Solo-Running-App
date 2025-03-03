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



@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    
    @Published var productIds: [Product.ID] = ["monthly_subscription", "yearly_subscription"]
    private var groupID =  "21636260"
    
    @Published var isSubscribed: Bool = false
    
    @Published var currentEntitlement: Transaction?
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
    
    func clearEntitlementData() {
        currentEntitlement = nil
    }

    func hasSubscriptionExpired() -> Bool {
        // If the user has no active entitlements, then they have no susbcription
        guard let entitlement = currentEntitlement else { return true}
        guard let renewalInfo = currentRenewalInfo else { return true}
        
        //print("Entitlement Expiration Date: \( String(describing: entitlement.expirationDate)) VS NOW Date: \(Date())")
        // print("Will sub auto renew: \(renewalInfo.willAutoRenew)")
        
        // Dont assume that that an empty expiration date means the subscription is still active
        guard let expirationDate = entitlement.expirationDate else { return true }
        
        let hasExpired = expirationDate < Date() && !renewalInfo.willAutoRenew
        // print("Has susbcription expired: \(hasExpired)")
        
        return hasExpired
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
                        
            // Get the renewal information for the current subscription
            do {
                let products = try await Product.products(for: [transaction.productID])
                for product in products {
                    do {
                        let productSubInfo = try await product.subscription?.status
                        
                        for subInfo in productSubInfo! {
                            if subInfo.state == .subscribed && subInfo.state != .expired {
                                // print("SUB INFO: \(subInfo)")
                                switch subInfo.renewalInfo {
                                case .verified(let prodStatus):
                                    if (prodStatus.currentProductID == transaction.productID) {
                                        currentEntitlement = transaction
                                        transactionPayload = result.payloadData
                                        currentRenewalInfo = prodStatus
                                    }
                                    break
                                default:
                                    break
                                }
                            } else {
                                currentEntitlement = nil
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
        
        self.isLoadingEntitlement = false

    }
}


// if(prodStatus.autoRenewPreference != nil) && (prodStatus.autoRenewPreference != transaction.productID){
//     nextRenewalInfo = prodStatus
// }
