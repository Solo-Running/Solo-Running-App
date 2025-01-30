//
//  SpotifyManager.swift
//  Solo
//
//  Created by William Kim on 11/14/24.
//

import Foundation
import SwiftUI
import Combine
import SpotifyiOS
import CommonCrypto


let scopes: SPTScope = [.appRemoteControl]
let stringScopes = [ "app-remote-control"]
var accessTokenKey = "access-token-key"
var sessionManagerKey = "session-manager-key"

@MainActor
final class SpotifyManager: NSObject, ObservableObject, UIApplicationDelegate {

    
    @Published var currentTrackURI: String?
    @Published var currentTrackName: String?
    @Published var currentTrackArtist: String?
    @Published var currentAlbum: String?
    @Published var currentTrackImage: UIImage?
    @Published var lastPlayerState: SPTAppRemotePlayerState?
    @Published var canSkipNext: Bool = true
    @Published var canSkipPrevious: Bool = true
    
    @Published var isLoading: Bool = false

    private var connectCancellable: AnyCancellable?
    private var disconnectCancellable: AnyCancellable?
    
    
    
    // Session Manager keeps track of the user's session status
    lazy var sessionManager: SPTSessionManager? = {
        self.configuration.playURI = ""
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
        
    // Spotify Player configuration with uique client id
    let configuration = SPTConfiguration(
        clientID:Bundle.main.infoDictionary?["SPOTIFY_CLIENT_ID"] as! String,
        redirectURL: URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    )
    
    // The main entry point for interfacing with Spotify player
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    
    func canOpenSpotify() -> Bool {
        // Use the associated spotify key written in LSApplicationQueriesSchemes from info.plist
        let canOpen = UIApplication.shared.canOpenURL(URL(string: "spotify://")!)
        return canOpen
    }
    
    // Pause or play control
    func togglePlayer() {
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }
    
    // Skip to next song
    func skipNext() {
        print("pressed skip")
        appRemote.playerAPI?.skip(toNext: { result, error in
               if let error = error {
                   print("Error skipping to next track: \(error.localizedDescription)")
               } else {
                   print("Successfully skipped to next track")
               }
        })
    }
    
    // Go back to previous song
    func goBack() {
        print("pressed go back")
        appRemote.playerAPI?.skip(toPrevious:{ result, error in
            if let error = error {
               print("Error skipping to next track: \(error.localizedDescription)")
            } else {
               print("Successfully skipped to next track")
            }
        })
    }
    
    // Check if the Spotify Player has been paused
    func isPlayerPaused() -> Bool {
        if lastPlayerState != nil {
            return lastPlayerState!.isPaused
        }
        return false
    }
    
    // Check if the session has expired
    func isSessionExpired() -> Bool{
        guard let manager = sessionManager, manager.session != nil else{
            return true
        }
        return manager.session!.isExpired
    }
    

    // Check if the app remote is connected
    func isAppRemoteConnected() -> Bool {
        return appRemote.isConnected
    }
    
    
    // Performs the actual connection logic to Spotify
    func connect(launchSession: Bool) {
        isLoading = true
        
        // First check if the access token exists in User Defaults
        print("checking user defaults for session data")
        
        if let sessionData = UserDefaults.standard.data(forKey: sessionManagerKey) {
            do {
                // Decode the session with cast typing as a SPTSession
                if let session = try NSKeyedUnarchiver.unarchivedObject(ofClass: SPTSession.self, from: sessionData) {
                    
                    // Check if the SPTSession has expired
                    if session.expirationDate > Date() {
                        print("Session is still valid.")
                        
                        // Reinitialize the session and reconnect the user with the saved access token
                        self.sessionManager?.session = session
                        self.appRemote.connectionParameters.accessToken = session.accessToken
                        self.appRemote.connect()
                        
                    } else {
                        if launchSession {
                            print("Access token expired. Initiating new session.")
                            sessionManager?.initiateSession(with: scopes, options: .clientOnly, campaign: nil)
                        }
                    }
                } else {
                    print("Failed to cast the unarchived object to SPTSession.")
                }
            } catch {
                print("Error unarchiving session: \(error)")
            }
        } else {
            print("No session data found in User Defaults.")
            if launchSession {
                print("Initiating new session.")
                sessionManager?.initiateSession(with: scopes, options: .clientOnly, campaign: nil)
            }
        }
        isLoading = false
    }
    
    
    func resumePlayback() {
        print("Resuming playback")
        // Connect normally
        connect(launchSession: false)
        
        // If failed, launch a new session
        if !isAppRemoteConnected() {
            print("Normal connection failed. Launching new session")
            sessionManager?.initiateSession(with: scopes, options: .clientOnly, campaign: nil)
        } else {
            print("Normal connection success")
        }
        
    }
    
    
    // This callback function will tell the SPTSessionManagerDelegate to initiate
    func onAuthCallback(open url: URL)  {
        sessionManager?.application(UIApplication.shared, open: url, options: [:])
    }
    
    
    // Disconnects the app remote and  nullifies the Spotify session
    func disconnect() {
        if appRemote.isConnected {
            // Stop the music
            togglePlayer()
            
            // Disconnect app remote and reset the session manager
            appRemote.disconnect()
            sessionManager?.session.self = nil

            // Remove the session from storage
            UserDefaults.standard.removeObject(forKey: sessionManagerKey)
            print("Successfully disconnected")
        }
    }
    
    
    // Keep user's player state in sync with spotify player
    func update(playerState: SPTAppRemotePlayerState) {
        
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchImage(track: playerState.track)
        }
        
        self.lastPlayerState = playerState
        self.currentTrackURI = playerState.track.uri
        self.currentTrackName = playerState.track.name
        self.currentAlbum = playerState.track.album.name
        self.currentTrackArtist = playerState.track.artist.name
        self.canSkipNext = playerState.playbackRestrictions.canSkipNext
        self.canSkipPrevious = playerState.playbackRestrictions.canSkipPrevious
    }
            
}




// Subscribe to the plater state after connecting to Spotify
extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("established spotify app remote connection")
        self.appRemote = appRemote
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                print("Error subscribing to player state: \(error.localizedDescription)")
            } else {
                print("Successfully subscribed to player state")
            }
        })
        
        fetchPlayerState()
        isLoading = false
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnect error: \(String(describing: error))")
        self.lastPlayerState = nil
        isLoading = false
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Connection attempt error: \(String(describing: error))")
        lastPlayerState = nil
        isLoading = false
    }
  
}




// This delegate method is invoked whenever there's a change in the player's state from the actual spotify app
extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("received updated from SPTAppRemotePlayerStateDelegate")
        self.update(playerState: playerState)
    }
}




extension SpotifyManager: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if !error.localizedDescription.isEmpty {
            print("Authorization failed \(error.localizedDescription)")
        }
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
                
        print("session initiated. Saving to user defaults")
        do {
            let sessionData = try NSKeyedArchiver.archivedData(withRootObject: session, requiringSecureCoding: false)
            UserDefaults.standard.set(sessionData, forKey: sessionManagerKey)
            print("Session saved successfully: \(sessionData)")
        } catch {
            print("Failed to save session: \(error)")
        }
        
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
    
    // Not really needed but required to implement the delegate extension
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session renewed \(session.description)")
    }
}


extension SpotifyManager {

    func fetchImage(track: SPTAppRemoteTrack) {
        self.appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize(width: 300, height: 300), callback: { (image, error) in
            if let error = error {
                print("Error fetching track image: \(error.localizedDescription)")
            } else if let image = image as? UIImage {
                DispatchQueue.main.async {
                    self.currentTrackImage = image
                }
            }
        })
    }
    
    func fetchPlayerState() {
        print("fetching player state")

        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
}


