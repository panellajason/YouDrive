//
//  Group.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Object for defining a drive for a user in a group.
class Drive {
    var distance: String
    var groupName: String
    var location: String
    var newPoints: String
    var numberOfPassengers: String
    var oldPoints: String
    var userId: String
    var username: String

    init(distance: String, groupName: String, location: String, newPoints: String, numberOfPassengers: String,  oldPoints: String, userId: String, username: String) {
        self.distance = distance
        self.groupName = groupName
        self.location = location
        self.newPoints = newPoints
        self.numberOfPassengers = numberOfPassengers
        self.oldPoints = oldPoints
        self.userId = userId
        self.username = username
    }
}
