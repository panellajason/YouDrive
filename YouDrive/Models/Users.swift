//
//  Users.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import Foundation

class User {
    var userID: String
    var favoriteTours = [Tour]()

    init(userID:String, favoriteTours: [Tour]) {
        self.userID = userID
        self.favoriteTours = favoriteTours
    }
}
