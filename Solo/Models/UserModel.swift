//
//  UserModel.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftData
import SwiftUI


@Model
public class UserModel {
    public var id: String = UUID().uuidString
    var fullName: String = ""
    var streak: Int = 0
    var streakLastDoneDate: Date?
    @Attribute(.externalStorage) var profilePicture: Data?

    init(id: String, fullName: String, streak: Int = 0, streakLastDoneDate: Date? = Date(), profilePicture: Data?) {
        self.id = id
        self.fullName = fullName
        self.streak = streak
        self.streakLastDoneDate = streakLastDoneDate
        self.profilePicture = profilePicture

    }
}

