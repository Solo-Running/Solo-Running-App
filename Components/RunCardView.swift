//
//  RunCard.swift
//  Solo
//
//  Created by William Kim on 10/29/24.
//

import Foundation
import SwiftUI

struct RunCardView: View {
    var run: Run!
    
    var body: some View {
        NavigationLink(destination: RunDetailView(runData: run)) {
            
            HStack(alignment: .top) {
                
                if let uiImage = UIImage(data: run.routeImage) {
                    VStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(width: 80, height: 80 )
                    .padding(.trailing, 8)
                }
                
                VStack(alignment: .leading) {
                    
                    Text(run.startTime.formatted(
                        .dateTime
                            .day()
                            .month(.abbreviated)
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                    .padding(.bottom, 0)
                    
                    
                    Text("\(convertDateToString(date: run.startTime)) - \(convertDateToString(date: run.endTime))")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .font(.subheadline)
                    
                    HStack  {
                        
                        // Custom pin
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 14, height: 14)
                                
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(run.endPlacemark.isCustomLocation ? .yellow : DARK_GREY)
                                    .font(.system(size: 4))
                            }
                            
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.caption)
                                .foregroundStyle(run.endPlacemark.isCustomLocation ? .yellow : DARK_GREY)
                                .offset(x: 0, y: -8)
                        }
                        
                        
                        Text((run.endPlacemark.name)!)
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
}




