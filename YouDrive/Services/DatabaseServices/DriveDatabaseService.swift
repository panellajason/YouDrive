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
    static func addDriveToGroup(driveToAdd: Drive, completion: @escaping(Error?) ->()) {
     
        databaseInstance.collection(DatabaseCollection.drives.rawValue).addDocument(data: [
            DatabaseField.distance.rawValue: driveToAdd.distance,
            DatabaseField.group_name.rawValue: driveToAdd.groupName,
            DatabaseField.location.rawValue: driveToAdd.location,
            DatabaseField.number_of_passengers.rawValue: driveToAdd.numberOfPassengers,
            DatabaseField.points.rawValue: String((Double(driveToAdd.newPoints) ?? 0.0) - (Double(driveToAdd.oldPoints) ?? 0.0)),
            DatabaseField.user_id.rawValue: driveToAdd.userId,
            DatabaseField.username.rawValue: driveToAdd.username
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            let userGroup = UserGroup(groupName: driveToAdd.groupName, pointsInGroup: driveToAdd.newPoints , userId: driveToAdd.userId, username: driveToAdd.username)

            GroupDatabaseService.updateUserGroupsDocument(userGroupToUpdate: userGroup) { error in

                guard error == nil else {
                    return
                }

                completion(error)
            }
        }
    }
}

// Delegate for updating HomeViewCcontroller after adding a drive.
protocol AddDriveDelegate {
    func onDriveAdded()
}
