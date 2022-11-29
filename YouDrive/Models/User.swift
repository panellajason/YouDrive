//
//  Users.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import Foundation

// Object for defining a user.
class User {
    var email: String
    var homeGroup: String
    var iconId: Int
    var userId: String
    var username: String

    init(email: String, homeGroup: String, iconId: Int, userId: String, username: String) {
        self.email = email
        self.homeGroup = homeGroup
        self.iconId = iconId
        self.userId = userId
        self.username = username
    }
}
