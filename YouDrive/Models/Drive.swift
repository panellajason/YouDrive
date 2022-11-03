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
    var numberOfPassengers: String
    var pointsEarned: Double
    var timestamp: String
    var user: UserGroup

    init(distance: String, groupName: String, location: String, numberOfPassengers: String, pointsEarned: Double, timestamp: String, user: UserGroup) {
        self.distance = distance
        self.groupName = groupName
        self.location = location
        self.numberOfPassengers = numberOfPassengers
        self.pointsEarned = pointsEarned
        self.timestamp = timestamp
        self.user = user
    }
}
