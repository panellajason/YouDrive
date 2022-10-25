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
    static func addDriveToGroup(amount: String, distance: String, groupName: String, location: String, numberOfPassengers: String, whoPaid: String, completion: @escaping(Error?) ->()) {
     
        databaseInstance.collection(DatabaseCollection.drives.rawValue).addDocument(data: [
            DatabaseField.amount.rawValue: amount,
            DatabaseField.distance.rawValue: distance,
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.location.rawValue: location,
            DatabaseField.number_of_passengers.rawValue: numberOfPassengers,
            DatabaseField.user_id.rawValue: (UserDatabaseService.currentUserProfile?.userId ?? "") as String,
            DatabaseField.who_paid.rawValue: whoPaid,
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
