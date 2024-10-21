//
//  ProvideCredentialsView.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ProvideCredentialsView: View {
    
    @State private var fullname: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var showErrorDialog: Bool = false
    
    

    var body: some View {
        
        VStack(alignment: .center, spacing: 24) {

            Text("Set Up Profile")
                .font(Font.custom("Koulen-Regular", size: 24))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(NEON)
                        
            Spacer()
            
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Group {
                    if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill) // Ensure the image fills the frame
                            .clipped()

                    } else {
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
                if (fullname.isEmpty || selectedPhoto == nil) {
                    showErrorDialog = true
                } else {
                    showErrorDialog = false
                    let user = UserModel(id: UUID().uuidString, fullName: fullname, profilePicture: selectedPhotoData)
                    modelContext.insert(user)
                    
                    print("inserted credentials into swift data")
                
                    appState.hasCredentials = true
                }
            } label : {
                Text("Let's go!").foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 32)
            }
            
            Spacer()

        }
        .padding([.leading, .trailing], 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .alert("Please ensure you choose a picture and name", isPresented: $showErrorDialog) {
            Button("OK", role: .cancel){}
        }
    }
}



