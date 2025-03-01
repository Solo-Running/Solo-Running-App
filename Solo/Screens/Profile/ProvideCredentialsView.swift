//
//  ProvideCredentialsView.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI
import PhotosUI


/**
 Provides a basic form to input a name and profile image when the user first creates their profile.
 Do note that this information is purely for user experience and is not shared with anyone.
 */
struct ProvideCredentialsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityManager: ActivityManager
    
    @State private var fullname: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data? = nil
    
    @State private var showErrorDialog: Bool = false
    
    @State private var showPermissionsSheet: Bool = false
    @State private var permissionsSheetDetents: Set<PresentationDetent> =  [.large]
    
    

    var body: some View {
        
        VStack(alignment: .center, spacing: 24) {
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
                }
                else if !activityManager.isMotionAuthorized || !locationManager.isAuthorized {
                    showPermissionsSheet = true
                }
                else {
                    showErrorDialog = false
                    let user = UserModel(id: UUID().uuidString, fullName: fullname, streak: 0, streakLastDoneDate: nil,  profilePicture: selectedPhotoData)
                    modelContext.insert(user)
                    
                    print("inserted credentials into swift data")
                
                    appState.hasCredentials = true
                }
            } label : {
                HStack {
                    Text("Let's go")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(BLUE)
                .cornerRadius(12)
                
            }
            
            Spacer().frame(height: 32)
            

        }
        .padding([.leading, .trailing], 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .alert("Please ensure you choose a picture and name", isPresented: $showErrorDialog) {
            Button("OK", role: .cancel){}
        }
        .sheet(isPresented: $showPermissionsSheet, onDismiss: {
            // Check if the user updated their permissions from the settings
            activityManager.checkAuthorization()
        }) {
            PermissionsView()
                .presentationDetents(permissionsSheetDetents)
        }
    }
}


/**
 An informative presentation that appears whenever a user tries to open the app or start a run
 without first having permissions enabled for location and core motion. It comes with a button
 to direct the user to the app's settings.
 */
struct PermissionsView: View {
    var body: some View {
        VStack(alignment: .leading) {
                        
            Text("Need Permissions")
                .foregroundStyle(.white)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 16)
        
            Text("In order to use certain features of the app, you need to enable the following permissions. See descriptions for each permission.")
                .foregroundStyle(TEXT_LIGHT_GREY)
                .padding(.bottom, 32)
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            
            VStack(alignment: .leading) {
                    
                VStack(alignment: .leading) {
                    Text("Location")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .font(.title3)
                    
                    Text("Allow access to your location while running")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .font(.subheadline)
                }
                .padding(EdgeInsets(top: 24, leading: 16,  bottom: 16, trailing: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().padding(.horizontal, 16)
                
                VStack(alignment: .leading) {
                    Text("Core Motion")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .font(.title3)
                    
                    Text("Track stats during physical activity")
                        .foregroundStyle(TEXT_LIGHT_GREY)
                        .font(.subheadline)
                }
                .padding(EdgeInsets(top: 16, leading: 16,  bottom: 24, trailing: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(.black))
            .padding(.bottom, 32)


            Text("Permissions are necessary for all features to work properly. Without location permission, you won't be able to use the maps feature. Without core motion permission, you won't be able to track steps or distance.")
                .foregroundStyle(TEXT_LIGHT_GREY)
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .padding(.bottom, 32)
            
            Button {
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                   if UIApplication.shared.canOpenURL(appSettings) {
                       UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                   }
                }
            } label: {
                VStack(alignment: .center) {
                    Text("Settings")
                        .fontWeight(.semibold)
                        .foregroundStyle(TEXT_LIGHT_GREEN)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(LIGHT_GREEN)
                .cornerRadius(12)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .presentationBackground(DARK_GREY)
    }
}

