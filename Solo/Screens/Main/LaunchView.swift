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
            Image("SoloLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 240,height: 240)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)       
    }
}
