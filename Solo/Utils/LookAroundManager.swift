//
//  LookAroundManager.swift
//  Solo
//
//  Created by William Kim on 4/18/25.
//

import Foundation
import SwiftUI
import MapKit

class LookAroundManager: ObservableObject {

    var lookAroundScene: MKLookAroundScene?
    var coordinate: CLLocationCoordinate2D?
    
    func resetData() {
        lookAroundScene = nil
        coordinate = nil
    }
    
    func loadPreview() async {
        Task {
            if let coordinate = coordinate {
                let request = MKLookAroundSceneRequest(coordinate: coordinate)
                do {
                    lookAroundScene = try await request.scene
                } catch (let error) {
                    print(error)
                }
            }
        }
    }
    
}
