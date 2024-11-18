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

@MainActor
final class SpotifyManager: NSObject, ObservableObject {

    
    @Published var currentTrackURI: String?
    @Published var currentTrackName: String?
    @Published var currentTrackArtist: String?
    @Published var currentTrackDuration: Int?
    @Published var currentTrackImage: UIImage?
    @Published var playBackPosition: Int?
    @Published var lastPlayerState: SPTAppRemotePlayerState?
    
    @Published var isLoading: Bool = false

    private var connectCancellable: AnyCancellable?
    private var disconnectCancellable: AnyCancellable?
    
    var accessToken = UserDefaults.standard.string(forKey: accessTokenKey) {
       didSet {
           let defaults = UserDefaults.standard
           defaults.set(accessToken, forKey: accessTokenKey)
       }
    }
    
    // When the response code is updated, get the accessToken
    var responseCode: String? {
        didSet {
            // The access token will enable the app remote instance to manipulate the spotify player
            fetchAccessToken()
        }
    }
      
    let configuration = SPTConfiguration(
        clientID:Bundle.main.infoDictionary?["SPOTIFY_CLIENT_ID"] as! String,
        redirectURL: URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    )
    
    // The main entry point for interfacing with Spotify player
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    // Session Manager keeps track of the user's session status
    lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    // Pause or play
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
    
    func isPlayerPaused() -> Bool {
        if lastPlayerState != nil {
            return lastPlayerState!.isPaused
        }
        return false
    }
    
    func isSessionExpired() -> Bool{
        if let manager = sessionManager, manager.session != nil  {
            print("is session expired \(manager.session?.isExpired)")
            return manager.session!.isExpired
        }
        return true
    }
    
    
    func isAppRemoteConnected() -> Bool {
        return appRemote.isConnected
    }
    
    func connect() {
        print("starting session")
        isLoading = true
        guard let sessionManager = sessionManager else { return }
        sessionManager.initiateSession(with: scopes, options: .clientOnly, campaign: nil)
    }
    
    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
            print("app remote disconnected")
        }
    }
    
    func reconnect() {
        appRemote.connect()
    }
    
    // Invoked when use navigates back from authentication to save the response code
    func saveResponseCode(from url: URL) {
        print("setting access token from url: \(url)")

        let parameters = self.appRemote.authorizationParameters(from: url)
        
        if let code = parameters?["code"] {
            self.responseCode = code
        } else if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            self.accessToken = access_token
        }
        else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print(errorDescription)
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
        self.currentTrackArtist = playerState.track.artist.name
        self.currentTrackDuration = Int(playerState.track.duration) / 1000 // playerState.track.duration is in milliseconds
        self.playBackPosition = playerState.playbackPosition
    }

    
            
}

// Subscribe to the plater state after connecting to Spotify
extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("established spotify connection")
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
        self.update(playerState: playerState)
    }
}

extension SpotifyManager: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
        } else {
            print("Authorization failed \(error.localizedDescription)")
        }
        isLoading = false
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session renewed \(session.description)")
    }

    // Reconnect without having to authorize again
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        if session.isExpired {
            print("session expired, renewing")
            sessionManager!.renewSession()
        }
                
        print("session initiated")
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
        
        print("called appRemote.connect()")
        isLoading = false

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
    
    func challenge(verifier: String) -> String {
        
        guard let verifierData = verifier.data(using: String.Encoding.utf8) else { return "error" }
            var buffer = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
     
            verifierData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, CC_LONG(verifierData.count), &buffer)
            }
        let hash = Data(_: buffer)
        print(hash)
        let challenge = hash.base64EncodedData()
        return String(decoding: challenge, as: UTF8.self)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    
    func fetchAccessToken() {
 
        let spotifyURL = "https://accounts.spotify.com/api/token"
        let spotifyClientID = Bundle.main.infoDictionary?["SPOTIFY_CLIENT_ID"] as! String
        let spotifyClientSecretKey = Bundle.main.infoDictionary?["SPOTIFY_CLIENT_SECRET_KEY"] as! String
        let redirectURL = URL(string:"spotify-ios-quick-start://spotify-login-callback")!

        
        var request = URLRequest(url: URL(string: spotifyURL)!)
           request.httpMethod = "POST"
           request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // Encode credentials in Base64
            let credentials = "\(spotifyClientID):\(spotifyClientSecretKey)"
               .data(using: .utf8)?
               .base64EncodedString() ?? ""
            
            request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

            let pkceProvider = sessionManager!.value(forKey: "PKCEProvider")
            guard let codeVerifier = (pkceProvider as AnyObject).value(forKey: "codeVerifier") as? String else {return}
        
                
            // Body parameters
            let bodyParameters = [
               "grant_type": "authorization_code",
               "code": responseCode!,
               "redirect_uri": redirectURL.absoluteString,
               "code_verifier": codeVerifier
            ]

            // Convert parameters to x-www-form-urlencoded format
            request.httpBody = bodyParameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                .joined(separator: "&")
                .data(using: .utf8)
        
            print(request.httpBody)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Response JSON: \(json)")
                        if let accessToken = json["access_token"] as? String {
                            DispatchQueue.main.async {
                                self.accessToken = accessToken
                                self.appRemote.connectionParameters.accessToken = accessToken
                                self.appRemote.connect()
                            }
                        }  else if let error = json["error"] as? String {
                            print("Error: \(error)")
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
            task.resume()
    }
}


// If connecting for the first time
//        guard let accessToken = self.appRemote.connectionParameters.accessToken, !appRemote.isConnected else {
//            self.appRemote.authorizeAndPlayURI("")
//            return
//        }
//
//        // reconnect again
//        appRemote.connect()
