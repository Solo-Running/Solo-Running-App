//
//  LaunchView.swift
//  Solo
//
//  Created by William Kim on 10/23/24.
//

import Foundation
import SwiftUI
import SwiftData

/**
 Renders the app logo when first launching the application.
 */
struct LaunchView: View {

    var body: some View {
        
        VStack{
            
            Text("SOLO")
//                .font(Font.custom("Koulen-Regular", size: 48))
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)       
    }
}
