//
//  Database.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Database collection names in firestore.
enum DatabaseCollection: String {
    case drives
    case events
    case groups
    case users
    case user_groups
}

// Database field names in firestore.
enum DatabaseField: String {
    case distance
    case email
    case home_group
    case host
    case icon_id
    case group_name
    case group_passcode
    case location
    case number_of_passengers
    case points
    case timestamp
    case type
    case user_id
    case username
}
