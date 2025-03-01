//
//  RecentPurchasesView.swift
//  Solo
//
//  Created by William Kim on 3/1/25.
//

import Foundation
import SwiftUI
import StoreKit

struct RecentPurchasesView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
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
        VStack {
            if subscriptionManager.isLoadingPurchases {
                ProgressView()
                
            } else {
                ScrollView {
                    
                    let sortedPurchases = subscriptionManager.recentPurchases.sorted { $0.purchaseDate > $1.purchaseDate }
                    
                    LazyVStack {
                        ForEach(sortedPurchases, id: \.self) { purchase in
                            
                            HStack(alignment: .center) {
                                  
                                VStack(alignment: .leading) {
                                    Text(formatTransactionProductID(purchase.productID))
                                        
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
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                            }
                            .onTapGesture {
                                presentRefundRequest(transaction: purchase)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .refreshable {
                    await subscriptionManager.getRecentPurchases()
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("All Purchases")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await subscriptionManager.getRecentPurchases()
                    }
                } label: {
                    
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .font(.subheadline)
                }
            }
        }
        .onAppear {
            Task {
                await subscriptionManager.getRecentPurchases()
            }
        }
        .onDisappear {
            subscriptionManager.recentPurchases.removeAll()
        }
    }
}
