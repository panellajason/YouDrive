//
//  Error.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// User credential validation errors.
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
