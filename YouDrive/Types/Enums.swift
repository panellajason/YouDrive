//
//  Enums.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import Foundation

// Database collection names in firestore
enum DatabaseCollection: String {
    case groups
    case users
    case user_drives
    case user_groups
}

// Database field names in firestore
enum DatabaseField: String {
    case host
    case group_name
    case group_passcode
    case points
    case user_id
}

// Segue names
enum SegueType: String {
    case toCreateAccount
    case toCreateGroup
    case toEntry
    case toHome
    case toNoGroups
    case toSearchResults
    case toSignIn
}

// User validation errors
enum ValidationError: Error {
    case invalidCredentials
    case emptyTextFields
    case passwordsMustMatch
}

extension ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .invalidCredentials:
                return NSLocalizedString(
                    "Username and/or passsword is incorrect.",
                    comment: ""
                )
            case .emptyTextFields:
                return NSLocalizedString(
                    "Fields cannot be empty.",
                    comment: ""
                )
            case .passwordsMustMatch:
                return NSLocalizedString(
                    "Passwords must match.",
                    comment: ""
                )
        }
    }
}
