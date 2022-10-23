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
    case groups
    case users
    case user_drives
    case user_groups
}

// Database field names in firestore.
enum DatabaseField: String {
    case amount
    case distance
    case drive_name
    case host
    case group_name
    case group_passcode
    case location
    case number_of_passengers
    case points
    case user_id
    case who_paid
}
