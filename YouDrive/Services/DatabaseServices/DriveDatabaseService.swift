//
//  DriveDatabaseService.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/24/22.
//

import Firebase
import Foundation

class DriveDatabaseService {
    
    private static var databaseInstance = UserDatabaseService.databaseInstance

    
    // Adds a document to "drives" table.
    static func addDriveToGroup(distance: String, groupName: String, location: String, numberOfPassengers: String, completion: @escaping(Error?) ->()) {
     
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        databaseInstance.collection(DatabaseCollection.drives.rawValue).addDocument(data: [
            DatabaseField.distance.rawValue: distance,
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.location.rawValue: location,
            DatabaseField.number_of_passengers.rawValue: numberOfPassengers,
            DatabaseField.user_id.rawValue: currentUser.userId,
            DatabaseField.username.rawValue: currentUser.username
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added document to "drives" table
            completion(error)
        }
    }
    
}
