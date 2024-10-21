//
//  DashboardView.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI
import SwiftData

struct DashboardView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query private var runs: [Run]
    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}

    @State var temperature: String = "98 F"
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                
                Spacer().frame(height: 24)

                Text("Recent run")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(TEXT_LIGHT_GREY)
                    
                
                
                Spacer()
                
                
                Text("Activity")
                
    
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            
                ToolbarItem(placement: .topBarLeading) {
                    Text(temperature)
                        .foregroundStyle(.white)
                        .background(DARK_GREY)
                        .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .cornerRadius(20.0)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Dashboard")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(NEON)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Group{
                           // Safely unwrap the user's profile picture and check if it's not empty
                           if let profileData = user?.profilePicture, !profileData.isEmpty, let profileImage = UIImage(data: profileData) {
                               Image(uiImage: profileImage)
                                   .resizable()
                                   .aspectRatio(contentMode: .fill) // Ensure the image fills the frame
                                   .clipped()
                           } else {
                               // If profile picture is empty, show a default person icon
                               Image(systemName: "person.fill")
                                   .resizable()
                                   .scaledToFit()
                                   .foregroundColor(.white)
                                   .frame(width: 16, height: 16)
                                
                           }
                       }
                        .frame(width: 32, height: 32)
                        .background(LIGHT_GREY)
                        .clipShape(Circle())

                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }

    }
}



