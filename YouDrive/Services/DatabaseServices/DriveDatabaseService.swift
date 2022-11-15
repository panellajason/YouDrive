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
            DatabaseField.icon_id.rawValue: driveToAdd.user.iconId,
            DatabaseField.location.rawValue: driveToAdd.location,
            DatabaseField.number_of_passengers.rawValue: driveToAdd.numberOfPassengers,
            DatabaseField.points.rawValue: driveToAdd.pointsEarned,
            DatabaseField.timestamp.rawValue: driveToAdd.timestamp,
            DatabaseField.user_id.rawValue: driveToAdd.user.userId,
            DatabaseField.username.rawValue: driveToAdd.user.username
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let oldPoints = Double(driveToAdd.user.pointsInGroup) else { return }
            let newPoints = (driveToAdd.pointsEarned + oldPoints).rounded(toPlaces: 1).description

            let userGroup = UserGroup(groupName: driveToAdd.groupName, iconId: driveToAdd.user.iconId, pointsInGroup: newPoints, userId: driveToAdd.user.userId, username: driveToAdd.user.username)
            
            GroupDatabaseService.updateUserGroupsDocument(userGroupToUpdate: userGroup) { error in

                guard error == nil else {
                    return
                }
                
                completion(error)
            }
                        
            let newEvent = Event(groupName: driveToAdd.groupName, iconId: driveToAdd.user.iconId, points: driveToAdd.pointsEarned, timestamp: Date().timeIntervalSince1970.description, type: EventType.DRIVE_ADDED.rawValue, username: driveToAdd.user.username)
            
            EventDatabaseService.createEventDoucment(event: newEvent) { error in
                
                guard error == nil else {
                    return
                }
                
                completion(error)
            }
        }
    }
    
    // Gets all drives for a group name.
    static func getAllDrivesForGroupName(groupName: String, completion: @escaping(Error?, [Drive]) -> ()) {
        
        databaseInstance.collection(DatabaseCollection.drives.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error, [])
                return
            }
                            
            guard let results = queryResults else {
                completion(error, [])
                return
            }
            
            if !results.documents.isEmpty {
                
                var drivesInGroup: [Drive] = []
                
                for document in results.documents {
                    
                    let data = document.data()
                    
                    guard let distance = data[DatabaseField.distance.rawValue] as? String else { return }
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? String else { return }
                    guard let location = data[DatabaseField.location.rawValue] as? String else { return }
                    guard let numberOfPassengers = data[DatabaseField.number_of_passengers.rawValue] as? String else { return }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return }
                    guard let user_id = data[DatabaseField.user_id.rawValue] as? String else { return }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return }

                    let user = UserGroup(groupName: groupName, iconId: iconId, pointsInGroup: points.description, userId: user_id, username: username)
                    //guard let pointsDouble = Double(points) else { return }

                    drivesInGroup.append(Drive(distance: distance, groupName: groupName, location: location, numberOfPassengers: numberOfPassengers, pointsEarned: points, timestamp: timestamp, user: user))
                }
                
                let sortedDrives = drivesInGroup.sorted(by: { $0.timestamp > $1.timestamp })
                return completion(error, sortedDrives)
            }
            // No drives found
            completion(error, [])
        }
    }
}

// Delegate for updating HomeViewCcontroller after adding a drive.
protocol AddDriveDelegate {
    func onDriveAdded(groupName: String)
}
