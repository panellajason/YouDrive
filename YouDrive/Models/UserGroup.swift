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
    var pointsInGroup: String
    var userName: String

    init(groupName: String, pointsInGroup: String, userName: String) {
        self.groupName = groupName
        self.pointsInGroup = pointsInGroup
        self.userName = userName
    }
}
