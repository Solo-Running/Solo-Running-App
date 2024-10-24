//
//  LaunchView.swift
//  Solo
//
//  Created by William Kim on 10/23/24.
//

import Foundation
import SwiftUI
import SwiftData


struct LaunchView: View {

    var body: some View {
        
        VStack{
            
            Text("SOLO")
                .font(Font.custom("Koulen-Regular", size: 48))
                .fontWeight(.heavy)
                .foregroundStyle(NEON)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)       
    }
}
