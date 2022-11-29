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
            DatabaseField.number_of_passengers.rawValue: driveToAdd.peopleInCar,
            DatabaseField.points.rawValue: driveToAdd.pointsEarned,
            DatabaseField.timestamp.rawValue: driveToAdd.timestamp,
            DatabaseField.user_id.rawValue: driveToAdd.user.userId,
            DatabaseField.username.rawValue: driveToAdd.user.username
        ]) { error in
            guard error == nil else { return completion(error) }
            
            let oldPoints = driveToAdd.user.pointsInGroup
            let newPoints = (driveToAdd.pointsEarned + oldPoints).rounded(toPlaces: 1)
            
            let userGroup = UserGroup(groupName: driveToAdd.groupName, iconId: driveToAdd.user.iconId, pointsInGroup: newPoints, userId: driveToAdd.user.userId, username: driveToAdd.user.username)
            GroupDatabaseService.updateUserGroupsDocument(userGroupToUpdate: userGroup) { error in
                guard error == nil else { return completion(error) }
                completion(error)
            }
            
            let newEvent = Event(groupName: driveToAdd.groupName, iconId: driveToAdd.user.iconId, points: driveToAdd.pointsEarned, timestamp: Date().timeIntervalSince1970.description, type: EventType.DRIVE_ADDED.rawValue, username: driveToAdd.user.username)
            EventDatabaseService.createEventDoucment(event: newEvent) { error in
                guard error == nil else { return completion(error) }
                completion(error)
            }
        }
    }
    
    // Deletes drive document.
    static func deleteDriveDocument(driveToDelete: Drive, completion: @escaping(Error?) ->()) {
        databaseInstance.collection(DatabaseCollection.drives.rawValue)
            .whereField(DatabaseField.timestamp.rawValue, isEqualTo: driveToDelete.timestamp)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error) }
            guard let results = queryResults else { return completion(error) }
                        
            if !results.documents.isEmpty {
                guard let document = results.documents.first else { return completion(error) }
                let docId = document.documentID
                                
                databaseInstance.collection(DatabaseCollection.drives.rawValue).document(docId).delete() { error in
                    guard error == nil else { return completion(error) }
                    
                    ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
                    HomeViewController.groupUpdatesDelegate?.onGroupUpdates()
                    
                    GroupDatabaseService.getAllUsersInGroup(groupName: driveToDelete.groupName) { error, users in
                        guard error == nil && users.count != 0 else { return completion(error) }
                        guard let user = users.first(where: {$0.username == driveToDelete.user.username}) else { return completion(error) }
                        
                        let oldPoints = user.pointsInGroup
                        let newPoints = (oldPoints - driveToDelete.pointsEarned).rounded(toPlaces: 1)
                        
                        let userGroup = UserGroup(groupName: driveToDelete.groupName, iconId: driveToDelete.user.iconId, pointsInGroup: newPoints, userId: driveToDelete.user.userId, username: driveToDelete.user.username)
                        GroupDatabaseService.updateUserGroupsDocument(userGroupToUpdate: userGroup) { error in
                            guard error == nil else { return completion(error) }
                            completion(error)
                        }
                        
                        let newEvent = Event(groupName: driveToDelete.groupName, iconId: driveToDelete.user.iconId, points: driveToDelete.pointsEarned, timestamp: Date().timeIntervalSince1970.description, type: EventType.DRIVE_DELETED.rawValue, username: driveToDelete.user.username)
                        EventDatabaseService.createEventDoucment(event: newEvent) { error in
                            guard error == nil else { return completion(error) }
                            completion(error)
                        }
                    }
                }
            }
            // No document found
            return completion(error)
        }
    }
    
    // Gets all drives for a group name.
    static func getAllDrivesForGroupName(groupName: String, completion: @escaping(Error?, [Drive]) -> ()) {
        databaseInstance.collection(DatabaseCollection.drives.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, []) }
            guard let results = queryResults else { return completion(error, []) }
            
            if !results.documents.isEmpty {
                var drivesInGroup: [Drive] = []
                for document in results.documents {
                    let data = document.data()
                    
                    guard let distance = data[DatabaseField.distance.rawValue] as? Double else { return completion(error, []) }
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, []) }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return completion(error, []) }
                    guard let location = data[DatabaseField.location.rawValue] as? String else { return completion(error, []) }
                    guard let peopleInCar = data[DatabaseField.number_of_passengers.rawValue] as? Int else { return completion(error, []) }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return completion(error, []) }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return completion(error, []) }
                    guard let user_id = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, []) }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return completion(error, []) }

                    let user = UserGroup(groupName: groupName, iconId: iconId, pointsInGroup: points, userId: user_id, username: username)
                    drivesInGroup.append(Drive(distance: distance, groupName: groupName, location: location, peopleInCar: peopleInCar, pointsEarned: points, timestamp: timestamp, user: user))
                }
                let sortedDrives = drivesInGroup.sorted(by: { $0.timestamp > $1.timestamp })
                return completion(error, sortedDrives)
            }
            // No drives found
            return completion(error, [])
        }
    }
}

// Delegate for updating HomeViewController after adding a drive.
protocol AddDriveDelegate {
    func onDriveAdded(groupName: String)
}
