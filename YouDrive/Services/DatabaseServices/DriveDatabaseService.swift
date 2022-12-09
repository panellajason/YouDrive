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
            
            let newEvent = Event(groupName: driveToAdd.groupName, iconId: driveToAdd.user.iconId, points: driveToAdd.pointsEarned, timestamp: Date().timeIntervalSince1970.description, type: EventType.DRIVE_ADDED.rawValue, userId: driveToAdd.user.userId, username: driveToAdd.user.username)
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
                        var newPoints = (oldPoints - driveToDelete.pointsEarned).rounded(toPlaces: 1)
                        
                        if newPoints < 0.0 {
                            newPoints = 0.0
                        }
                        
                        let userGroup = UserGroup(groupName: driveToDelete.groupName, iconId: driveToDelete.user.iconId, pointsInGroup: newPoints, userId: driveToDelete.user.userId, username: driveToDelete.user.username)
                        GroupDatabaseService.updateUserGroupsDocument(userGroupToUpdate: userGroup) { error in
                            guard error == nil else { return completion(error) }
                            completion(error)
                        }
                        
                        let newEvent = Event(groupName: driveToDelete.groupName, iconId: driveToDelete.user.iconId, points: driveToDelete.pointsEarned, timestamp: Date().timeIntervalSince1970.description, type: EventType.DRIVE_DELETED.rawValue, userId: driveToDelete.user.userId, username: driveToDelete.user.username)
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
                return completion(error, parseDrives(documents: results.documents))
            }
            // No drives found
            return completion(error, [])
        }
    }
    
    // Gets all drives for a user in a group.
    static func getAllDrivesForUserInGroup(groupName: String, userId: String, completion: @escaping(Error?, [Drive]) -> ()) {
        databaseInstance.collection(DatabaseCollection.drives.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, []) }
            guard let results = queryResults else { return completion(error, []) }
            
            if !results.documents.isEmpty {
                return completion(error, parseDrives(documents: results.documents))
            }
            // No drives found
            return completion(error, [])
        }
    }
    
    private static func parseDrives(documents: [QueryDocumentSnapshot]) -> [Drive] {
        var drivesInGroup: [Drive] = []
        for document in documents {
            let data = document.data()
            
            guard let distance = data[DatabaseField.distance.rawValue] as? Double else { return drivesInGroup }
            guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return drivesInGroup }
            guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return drivesInGroup }
            guard let location = data[DatabaseField.location.rawValue] as? String else { return drivesInGroup }
            guard let peopleInCar = data[DatabaseField.number_of_passengers.rawValue] as? Int else { return drivesInGroup }
            guard let points = data[DatabaseField.points.rawValue] as? Double else { return drivesInGroup }
            guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return drivesInGroup }
            guard let user_id = data[DatabaseField.user_id.rawValue] as? String else { return drivesInGroup }
            guard let username = data[DatabaseField.username.rawValue] as? String else { return drivesInGroup }

            let user = UserGroup(groupName: groupName, iconId: iconId, pointsInGroup: points, userId: user_id, username: username)
            drivesInGroup.append(Drive(distance: distance, groupName: groupName, location: location, peopleInCar: peopleInCar, pointsEarned: points, timestamp: timestamp, user: user))
        }
        let sortedDrives = drivesInGroup.sorted(by: { $0.timestamp > $1.timestamp })
        return sortedDrives
    }
    
    static func updateAllDrivesForUser(accountToUpdate: User, batch: WriteBatch, completion: @escaping(Error?, WriteBatch?) ->()) {
        databaseInstance.collection(DatabaseCollection.drives.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: accountToUpdate.userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, nil) }
            guard let results = queryResults else { return completion(error, nil) }
            
            if !results.documents.isEmpty {
                for document in results.documents {
                    let data = document.data()
                    let docId = document.documentID
                    let docRef = databaseInstance.collection(DatabaseCollection.drives.rawValue).document(docId)
                    
                    guard let distance = data[DatabaseField.distance.rawValue] as? Double else { return completion(error, nil) }
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, nil) }
                    guard let location = data[DatabaseField.location.rawValue] as? String else { return completion(error, nil) }
                    guard let peopleInCar = data[DatabaseField.number_of_passengers.rawValue] as? Int else { return completion(error, nil) }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return completion(error, nil) }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return completion(error, nil) }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, nil) }

                    let fields: [AnyHashable : Any] = [
                        DatabaseField.distance.rawValue: distance,
                        DatabaseField.group_name.rawValue: groupName,
                        DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                        DatabaseField.location.rawValue: location,
                        DatabaseField.number_of_passengers.rawValue: peopleInCar,
                        DatabaseField.points.rawValue: points,
                        DatabaseField.timestamp.rawValue: timestamp,
                        DatabaseField.user_id.rawValue: userId,
                        DatabaseField.username.rawValue: accountToUpdate.username,
                    ]
                    
                    batch.updateData(fields, forDocument: docRef)
                }
                return completion(error, batch)
            }
            // No drives found
            return completion(error, batch)
        }
    }
}

// Delegate for updating HomeViewController after adding a drive.
protocol AddDriveDelegate {
    func onDriveAdded(groupName: String)
}
