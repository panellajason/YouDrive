//
//  Group.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Object for defining a group.
class Group {
    var host: String
    var groupName: String
    var groupPasscode: String

    init(host: String, groupName: String, groupPasscode: String) {
        self.host = host
        self.groupName = groupName
        self.groupPasscode = groupPasscode
    }
}
