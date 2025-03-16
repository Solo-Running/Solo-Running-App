//
//  LoadDataView.swift
//  Solo
//
//  Created by William Kim on 3/9/25.
//

import Foundation
import SwiftUI


struct LoadDataView: View {
    var body: some View {
        VStack(alignment: .center) {
            ProgressView()
            
            Text("Loading your iCloud data. Please wait.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .padding(.top, 8)
                .foregroundStyle(TEXT_LIGHT_GREY)
        }
        .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
    }
}
