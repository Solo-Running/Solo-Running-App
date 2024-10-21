//
//  RunSummaryView.swift
//  Solo
//
//  Created by William Kim on 10/19/24.
//

import Foundation
import SwiftUI
import SwiftData

struct RunSummaryView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    @Environment(\.modelContext) private var modelContext
    
    @Query private var runs: [Run]
    var savedRun: Run? {runs.first}

    
    var body: some View {
        
        Text("test")
//        NavigationStack {
//            VStack(alignment: .leading){
//                Text(savedRun?.endLocation.name ?? "")
//                    .font(.title)
//                Text("Distance traveled: \(savedRun?.distanceTraveled ?? 0)")
//                Text("Average Speed: \(savedRun?.avgSpeed ?? 0)")
//
//                if let imageData = savedRun?.routeImage, let uiImage = UIImage(data: imageData) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                }
//                
//            }
//            .foregroundStyle(.white)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                
//                ToolbarItem(placement: .principal) {
//                    Text("Run Summary")
//                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//                        .foregroundColor(NEON)
//                }
//            }
//        }
        
    }
}
