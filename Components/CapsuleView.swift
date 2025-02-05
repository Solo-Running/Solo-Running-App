//
//  CapsuleView.swift
//  Solo
//
//  Created by William Kim on 10/24/24.
//

import Foundation
import SwiftUI

struct CapsuleView: View {
    var background: Color
    var iconName: String
    var iconColor: Color
    var text: String
    
    var body: some View {
        
        HStack(spacing: 8) {
             
            if !iconName.isEmpty {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 14))
            }
        
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TEXT_LIGHT_GREY)
            
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Capsule().fill(background))

    }
}
