//
//  SubscriptionsManager.swift
//  Solo
//
//  Created by William Kim on 1/27/25.
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionsManager: NSObject, ObservableObject {
    
    @Published var isSubscribed: Bool = false
    @Published var currentTransaction: Transaction?
    @Published var transactionPayload: Data?
    
    
    override init() {
        super.init()
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func checkSubscriptionStatus() async {
        
        var status: Bool = false
        
        // Iterate through the user's purchased products.
        for await verificationResult in Transaction.currentEntitlements {
            print("veritifcation Result: \(verificationResult)")
            switch verificationResult {
            case .verified(let transaction):
                status = true
                currentTransaction = transaction
                transactionPayload = verificationResult.payloadData
            case .unverified(_, _):
               print("not verified")
            }
        }
        
        isSubscribed = status
    }

}
