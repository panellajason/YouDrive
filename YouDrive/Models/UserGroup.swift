//
//  UserGroup.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/23/22.
//

import Foundation

// Object for defining the relationship between a user and a group.
class UserGroup {
    var groupName: String
    var iconId: String
    var pointsInGroup: String
    var userId: String
    var username: String

    init(groupName: String, iconId: String, pointsInGroup: String, userId: String, username: String) {
        self.groupName = groupName
        self.iconId = iconId
        self.pointsInGroup = pointsInGroup
        self.userId = userId
        self.username = username
    }
}
