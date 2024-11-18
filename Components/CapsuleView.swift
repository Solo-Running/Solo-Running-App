//
//  CapsuleView.swift
//  Solo
//
//  Created by William Kim on 10/24/24.
//

import Foundation
import SwiftUI

struct CapsuleView: View {
    var iconBackground: Color?
    var iconName: String
    var iconColor: Color
    var text: String
    
    var body: some View {
        
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconBackground ?? .clear)
                    .frame(width: 20, height: 20)
                
                if !iconName.isEmpty {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 12))
                }
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TEXT_LIGHT_GREY)
            
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Capsule().fill(LIGHT_GREY))

    }
}
