//
//  ProfileView.swift
//  Solo
//
//  Created by William Kim on 10/14/24.
//

import Foundation
import SwiftUI
import SwiftData
import AlertToast
import StoreKit


struct ProfileView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}

    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("isLiveActivityEnabled") var isLiveActivityEnabled = true
    @AppStorage("isSpotifyEnabled") var isSpotifyEnabled = false
    
    @State private var showEditCustomPinsView: Bool = false
    @State private var showSubscriptionsView: Bool = false
    
    @State private var showDeleteRunsDialog: Bool = false
    @State private var deleteStatus: DeleteStatus = .initial
    @State private var showDeleteToast: Bool = false
    @State private var showEmptyRunsToast: Bool = false

    
    var body: some View {

        NavigationStack {
            ScrollView(showsIndicators: false) {
                
                Spacer().frame(height: 48)
                
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
                
                
                NavigationLink(destination:  EditProfileView()) {
                    Text("Edit Profile")
                        .foregroundStyle(.white)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(DARK_GREY)
                
                Spacer().frame(height: 48)
                
                
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    
                    // Change map theme
                    VStack(alignment: .leading) {
                        Text("Features")
                            .font(.subheadline)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                                   
                        HStack(alignment: .center) {
                            VStack(alignment: .leading){
                                Text("Map Theme")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("Toggle your map theme to light or dark mode")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { !isDarkMode },       // Invert the value for the toggle
                                set: { isDarkMode = !$0 }   // Invert the value when the toggle changes
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: TEXT_LIGHT_GREY))
                            .frame(maxWidth: 48)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    }
                    
                    // Navigation to edit custom pins
                    Button {
                        showEditCustomPinsView = true
                    } label: {
                        HStack(alignment: .center) {
                            Text("Edit custom pins for your runs")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .frame(width: 24, height: 24)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    }
                    
                    
                    Spacer().frame(height: 16)
                    
                    
                    
                    // Manage Subscriptions
                    VStack(alignment: .leading) {
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundStyle(TEXT_LIGHT_GREY)
                           
                        NavigationLink {
                            SubscriptionEditView()
                        } label: {
                            HStack(alignment: .center) {
                                Text("Subscription Details")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                    .frame(width: 24, height: 24)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                        }
                    }
                    
                    
                    // Privacy Policy
                    Button {
                        // TODO: Add link to website
                    } label: {
                        HStack(alignment: .center) {
                            
                            Text("Privacy Policy")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Image(systemName: "shield")
                                .foregroundStyle(TEXT_LIGHT_GREY)
                                .frame(width: 24, height: 24)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    }
                    
                    
                    Spacer().frame(height: 24)
                    
                    // Delete all runs
                    Button {
                        showDeleteRunsDialog = true
                    } label: {
                        HStack(alignment: .center) {
                            
                            Text("Delete all runs")
                                .font(.subheadline)
                                .foregroundStyle(RED)
                            
                            Spacer()
                            
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showDeleteRunsDialog) {
                        Button("Yes", role: .destructive) {
                            
                            Task {
                                let fetchDescriptor = FetchDescriptor<Run>()
                                do {
                                    let runs = try modelContext.fetch(fetchDescriptor)
                                    if runs.count == 0 {
                                        showEmptyRunsToast = true
                                        return
                                    }
                                    showDeleteToast = true
                                    deleteStatus = .deleting
                                
                                    for run in runs {
                                        modelContext.delete(run)
                                    }
                                    
                                } catch {
                                    print("could not fetch runs with custom pin")
                                    deleteStatus = .failure
                                }
                                deleteStatus = .success
                            }
                        }
                    }
                    
                
                }
                                            
                Spacer().frame(height: 80)
            }
            .fullScreenCover(isPresented: $showEditCustomPinsView) {
                EditCustomPinsView(showView: $showEditCustomPinsView)
            }
            .toast(isPresenting: $showDeleteToast, tapToDismiss: true) {
                switch deleteStatus {
                case .deleting:
                    AlertToast(type: .loading)
                case .success:
                    AlertToast(type: .systemImage("checkmark.circle", Color.green), title: "Successfully deleted all runs")
                case .failure:
                    AlertToast(type: .systemImage("x.circle", Color.red), title: "An error occurred. Please try again")
                default:
                    AlertToast(type: .loading)
                }
            }
            .toast(isPresenting: $showEmptyRunsToast, tapToDismiss: true) {
                AlertToast(type: .regular, title: "There are no runs to delete")
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}



