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
    @Attribute(.unique) public var id: String = UUID().uuidString
    var fullName: String
    @Attribute(.externalStorage) var profilePicture: Data?

    
    init(id: String, fullName: String, profilePicture: Data?) {
        self.id = id
        self.fullName = fullName
        self.profilePicture = profilePicture
    }
}

