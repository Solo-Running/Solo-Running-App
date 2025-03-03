//
//  UserModel.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftData
import SwiftUI

/**
  Model that holds a user's name, profile pic, and run streak data.
 */
@Model
public class UserModel {
    public var id: String = UUID().uuidString
    var fullName: String = "User Name"
    var streak: Int = 0
    var streakLastDoneDate: Date?
    @Attribute(.externalStorage) var profilePicture: Data?

    init(fullName: String? = "User Name", streak: Int? = 0, streakLastDoneDate: Date? = Date(), profilePicture: Data? = nil) {
        self.fullName = fullName ?? ""
        self.streak = streak ?? 0
        self.streakLastDoneDate = streakLastDoneDate
        self.profilePicture = profilePicture
    }
}

