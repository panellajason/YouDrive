//
//  Group.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Object for defining a drive for a user in a group.
class Drive {
    var amount: String
    var distance: String
    var groupName: String
    var location: String
    var numberOfPassengers: String
    var userID: String
    var whoPaid: String

    init(amount: String, distance: String, groupName: String, location: String, numberOfPassengers: String, userID: String, whoPaid: String) {
        self.amount = amount
        self.distance = distance
        self.groupName = groupName
        self.location = location
        self.numberOfPassengers = numberOfPassengers
        self.userID = userID
        self.whoPaid = whoPaid
    }
}
