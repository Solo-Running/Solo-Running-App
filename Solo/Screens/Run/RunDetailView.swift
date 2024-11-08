//
//  RunDetailView.swift
//  Solo
//
//  Created by William Kim on 10/28/24.
//

import Foundation
import SwiftUI
import SwiftData


struct RunDetailView: View {
    
    var runData: Run!
        
    var body: some View {
        
        
        ScrollView(showsIndicators: false) {
            
            if let imageData = runData?.routeImage, let uiImage = UIImage(data: imageData) {
                ParallaxHeader(run: runData!) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .frame(height: 300)
            }
                
                                
            VStack(alignment: .leading) {
            
                Text("Details")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .fontWeight(.semibold)

                
                // Route start and end timeline
                VStack(spacing: 16) {
                    HStack {
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                        
                        
                        Text((runData?.startPlacemark.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                    .overlay(alignment: .topLeading){
                        Rectangle()
                            .fill(.white)
                            .frame(width: 1.5, height: 32)
                            .offset(y: 16)
                            .padding(.leading, 5.5)
                    }
                    
                    HStack {
                    
                        Circle()
                          .fill(.white)
                          .frame(width: 12, height: 12)
                        
                        Text((runData?.endPlacemark.name)!)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                        
                        Spacer()
                    }
                }

                Spacer().frame(height: 32)
  
                // Run statistics
                HStack {
                    Text("Distance (Meters)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text((String(format: "%.2f", runData!.distanceTraveled)))
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(LIGHT_GREY)
                .cornerRadius(12)
                
                HStack {
                    Text("Average Speed (MPH)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text((String(format: "%.2f", runData?.avgSpeed ?? 0)))
                        .foregroundStyle(.white)

                }
                .padding(20)
                .background(LIGHT_GREY)
                .cornerRadius(12)

                HStack {
                    Text("Avg Pace (Min/Mile)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()

                    Text("\(runData!.avgPace)")
                        .foregroundStyle(.white)

                }
                .padding(20)
                .background(LIGHT_GREY)
                .cornerRadius(12)
                        
                Spacer().frame(height: 48)

                Spacer()
            }
            .padding(.top)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(.black)
            
            

        }
        .defaultScrollAnchor(.bottom)
        .background(.black)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .bottomBar)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
            appearance.backgroundColor = UIColor(Color.black.opacity(0.2))
        }
    }
    
}

