//
//  DraggablePin.swift
//  Solo
//
//  Created by William Kim on 11/8/24.
//

import Foundation
import SwiftUI


struct DraggablePin: View {
    @Binding var isPinActive: Bool
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 20, height: 20)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundStyle(NEON)
            }
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(NEON)
                .offset(x: 0, y: -6)
    }
        .frame(width: 32, height: 32)
        .animation(.snappy, body:{ content in
            content.scaleEffect(isPinActive ? 1.2 : 1, anchor: .bottom)
            
        })
    }
}
