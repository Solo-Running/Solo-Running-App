//
//  ProfileView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//

import Foundation
import SwiftUI
import SwiftData

struct ProfileView: View {
    
    @Environment(\.modelContext) var modelContext
    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}

    
    var body: some View {
        NavigationStack {

            VStack {
                
                Spacer()
                
                // User profile image
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
                            .frame(width: 64, height: 64)
                        
                    }
                }
                .frame(width: 96, height: 96)
                .background(LIGHT_GREY)
                .clipShape(Circle())
                
                Spacer().frame(height: 12)
                
                // User full name
                if let data = user?.fullName {
                    Text(data)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else {
                    Text("user name")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                
                
                Spacer().frame(height: 12)

                
                Button{} label: {
                    Text("Edit profile")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                }
                .buttonBorderShape(.capsule)
                .background(DARK_GREY)
                
                Spacer()
                
                Button("Delete userData") {
                    Task {
                        let users = try modelContext.fetch(FetchDescriptor<UserModel>())
                        for user in users {
                            modelContext.delete(user)
                        }
                        try modelContext.save()
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
    }
}
