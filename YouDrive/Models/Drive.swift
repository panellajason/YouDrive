//
//  Group.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Object for defining a drive for a user in a group.
class Drive {
    var distance: Double
    var groupName: String
    var location: String
    var peopleInCar: Int
    var pointsEarned: Double
    var timestamp: String
    var user: UserGroup

    init(distance: Double, groupName: String, location: String, peopleInCar: Int, pointsEarned: Double, timestamp: String, user: UserGroup) {
        self.distance = distance
        self.groupName = groupName
        self.location = location
        self.peopleInCar = peopleInCar
        self.pointsEarned = pointsEarned
        self.timestamp = timestamp
        self.user = user
    }
}
