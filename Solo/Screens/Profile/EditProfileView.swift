//
//  EditProfileView.swift
//  Solo
//
//  Created by William Kim on 11/3/24.
//

import Foundation
import SwiftUI
import PhotosUI
import SwiftData
import AlertToast

struct EditProfileView: View {
    
    @Environment(\.modelContext) var modelContext
    @State private var fullname: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data? = nil
    @State private var showErrorDialog: Bool = false
    
    @State private var showSaveToast: Bool = false

    @Query var userData: [UserModel]
    var user: UserModel? {userData.first}
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                
                Spacer().frame(height: 48)
                
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Group {
                        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        }
                        else if let profileData = user?.profilePicture, !profileData.isEmpty && selectedPhoto == nil , let profileImage = UIImage(data: profileData) {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        }
                        
//                        if let profileData = user?.profilePicture, profileData.isEmpty && selectedPhoto == nil {
                        else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .tint(.white)
                                .frame(width: 48, height: 48)
                                .padding(24)
                                .background(LIGHT_GREY)
                                .cornerRadius(100.0)
                        }
                    }
                }
                .frame(width: 96, height: 96)
                .cornerRadius(100.0)
                .task(id: selectedPhoto) {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
                
                Spacer().frame(height: 48)
                
                TextField("", text: $fullname, prompt: Text("Full name").foregroundColor(.white))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .frame(height: 48)
                    .cornerRadius(12)
                    .padding(.leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(DARK_GREY)
                    )
                
            
                Spacer()
                
                
                Button {
                    if let profileData = user?.profilePicture, (profileData.isEmpty && selectedPhoto == nil) || fullname.isEmpty {
                        showErrorDialog = true
                    } 
                    else {
                        showErrorDialog = false
                                                
                        user?.fullName = fullname
                        if selectedPhoto != nil {
                            user?.profilePicture = selectedPhotoData
                        }
                        
                        try? modelContext.save()
                        showSaveToast = true
//
//                        let newUser: UserModel
//                        if selectedPhoto == nil {
//                            let photoData = (user?.profilePicture)!
//                            newUser = UserModel(id: UUID().uuidString, fullName: fullname, streak: 0, streakLastDoneDate: nil,  profilePicture: photoData)
//                        }
//                        else {
//                            newUser = UserModel(id: UUID().uuidString, fullName: fullname, streak: 0, streakLastDoneDate: nil,  profilePicture: selectedPhotoData)
//                        }
                    
//                            modelContext.delete(user!)
//                            modelContext.insert(newUser)
                       
                    }
                } label : {
                    Text("Save changes")
                        .foregroundStyle(BLUE)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .toast(isPresenting: $showSaveToast, tapToDismiss: true) {
                AlertToast(type: .systemImage("checkmark.circle", Color.green), title: "Successfully saved changes")
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                self.fullname = user?.fullName ?? ""
            }
            .alert("Please ensure you choose a picture and name", isPresented: $showErrorDialog) {
                Button("OK", role: .cancel){}
            }
        }
    }
}
