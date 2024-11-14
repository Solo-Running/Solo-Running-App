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
                        
                        CustomPin(background: Color.white, foregroundStyle: run.endPlacemark.isCustomLocation ? NEON : DARK_GREY)
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



struct CustomPin: View {
    
    @State var background: Color
    @State var foregroundStyle: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: 18, height: 18)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundStyle(foregroundStyle)
                    .font(.system(size: 4))
            }
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(foregroundStyle)
                .offset(x: 0, y: -7)
        }
    }
}



