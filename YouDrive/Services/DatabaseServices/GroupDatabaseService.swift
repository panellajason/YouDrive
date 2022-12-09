//
//  GroupDatabaseService.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/24/22.
//

import Firebase
import Foundation

class GroupDatabaseService {
    
    private static var databaseInstance = UserDatabaseService.databaseInstance

    static let defaultGroup = Group(host: "", groupName: "", groupPasscode: "")

    // Helper func to check if group credentials match a database document.
    private static func checkIfGroupCredentialsMatch(groupName: String, groupPasscode: String, completion: @escaping(Error?, Bool) ->()) {
        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.group_passcode.rawValue, isEqualTo: groupPasscode)
            .getDocuments()
        { (queryResults, error) in
            guard error == nil else { return completion(error, false) }
            guard let results = queryResults else { return completion(error, false) }
            return completion(error, !results.documents.isEmpty ? true : false)
        }
    }
    
    // Helper func to check if group name already exists in database.
    private static func checkIfGroupNameExists(groupName: String, completion: @escaping(Error?, String?) ->()) {
        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, nil) }
            guard let results = queryResults else { return completion(error, nil) }
            return completion(error, !results.documents.isEmpty ? "Group name already exists, try again." : nil)
        }
    }
    
    // Helper func to check if user is already a member of a group.
    private static func checkIfUserIsMemberOfGroup(groupName: String, completion: @escaping(Error?, Bool) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(nil, false) }
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: currentUser.userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, false) }
            guard let results = queryResults else { return completion(error, false) }
            return completion(error, !results.documents.isEmpty ? true : false)
        }
    }
    
    // Creates new group with current user as host.
    static func createNewGroup(groupName: String, groupPasscode: String, completion: @escaping(Error?, String?) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(nil, nil) }
        // Check if group name exists already
        checkIfGroupNameExists(groupName: groupName){ error, errorMessage in
            guard error == nil else { return completion(error, nil) }
            guard errorMessage == nil else {
                // Group name already exists, return with error message
                return completion(error, errorMessage)
            }
            // Since no group exists with this name, create new group
            createNewGroupDocument(groupName: groupName, groupPasscode: groupPasscode) { error in
                guard error == nil else { return completion(error, nil) }
                
                // Create users <-> groups document
                createUserGroupsDocument(groupName: groupName){ error in
                    guard error == nil else { return completion(error, nil) }
                    
                    // Create event
                    let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_CREATED.rawValue, userId: currentUser.userId, username: currentUser.username)
                    EventDatabaseService.createEventDoucment(event: newEvent) { error in
                        guard error == nil else { return completion(error, nil) }
                        
                        // Set home group of current user user to this group
                        let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, iconId: currentUser.iconId,  userId: currentUser.userId, username: currentUser.username)
                        UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate, batch: nil) { error, batch in
                            guard error == nil else { return completion(error, nil) }
                            
                            UserDatabaseService.currentUserProfile? = accountToUpdate
                            return completion(error, nil)
                        }
                    }
                }
            }
        }
    }
    
    // Helper func to add a document to "groups" table.
    private static func createNewGroupDocument(groupName: String, groupPasscode: String, completion: @escaping(Error?) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(nil) }
        databaseInstance.collection(DatabaseCollection.groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.group_passcode.rawValue: groupPasscode,
            DatabaseField.host.rawValue: currentUser.userId
        ]) { error in
            guard error == nil else { return completion(error) }
            // Successfully added document to "groups" table
            return completion(error)
        }
    }
    
    // Helper func to add a document to "userGroups" table.
    private static func createUserGroupsDocument(groupName: String, completion: @escaping(Error?) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(nil) }
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.icon_id.rawValue: currentUser.iconId,
            DatabaseField.points.rawValue: 0.0,
            DatabaseField.user_id.rawValue: currentUser.userId,
            DatabaseField.username.rawValue: currentUser.username
        ]) { error in
            guard error == nil else { return completion(error) }
            // Successfully added doument to "user_groups" table
            return completion(error)
        }
    }
    
    // Deletes userGroups document.
    static func deleteUserGroupsDocument(groupName: String, userId: String, completion: @escaping(Error?) ->()) {
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error) }
            guard let results = queryResults else { return completion(error) }
                        
            if !results.documents.isEmpty {
                guard let document = results.documents.first else { return completion(error) }
                let docId = document.documentID
                
                databaseInstance.collection(DatabaseCollection.user_groups.rawValue).document(docId).delete() { error in
                    guard error == nil else { return completion(error) }
                                        
                    ActivityFeedViewController.groupUpdatesDelegate?.onGroupUpdates()
                    ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
                    HomeViewController.groupUpdatesDelegate?.onGroupUpdates()
                    ManageGroupsViewController.groupUpdatesDelegate?.onGroupUpdates()
                    
                    guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(error) }
                    // Update homegroup of user if their homegroup got deleted
                    if currentUser.homeGroup == groupName {
                        let updatedUser = currentUser
                        
                        if UserDatabaseService.groupsForCurrentUser.count > 1 {
                            updatedUser.homeGroup = UserDatabaseService.groupsForCurrentUser.first(where: {$0 != updatedUser.homeGroup})!
                        } else {
                            updatedUser.homeGroup = ""
                        }
                        UserDatabaseService.currentUserProfile? = updatedUser

                        // Create event
                        let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_LEFT.rawValue, userId: currentUser.userId, username: currentUser.username)
                        EventDatabaseService.createEventDoucment(event: newEvent) { error in
                            guard error == nil else { return completion(error) }
                            completion(error)
                        }
                        
                        UserDatabaseService.updateUserDocument(accountToUpdate: updatedUser, batch: nil) { error, batch in
                            guard error == nil else { return completion(error) }
                            
                            guard UserDatabaseService.groupsForCurrentUser.count > 1 else {
                                NavigationService.showNoGroupsViewController()
                                return completion(error)
                            }
                            // Successfully deleted and updated home group for current user
                            return completion(error)
                        }
                    }
                    // Successfully deleted
                    return completion(error)
                }
            }
            // No document found
            return completion(error)
        }
    }
    
    // Joins existing group.
    static func joinGroup(groupName: String, groupPasscode: String, completion: @escaping(Error?, String?, Bool) ->()) {
        // Check if group credentials match a database record
        checkIfGroupCredentialsMatch(groupName: groupName, groupPasscode: groupPasscode) { error, doCredentialsMatch in
            guard error == nil else { return completion(error, nil, false) }
            
            if !doCredentialsMatch {
                // Credentials don't match
                return completion(error, nil, false)
            } else {
                // Check is user is already a member of this group
                checkIfUserIsMemberOfGroup(groupName: groupName){ error, isUserMemberInGroup in
                    guard error == nil else { return completion(error, nil, false) }
                    
                    if isUserMemberInGroup {
                        return completion(error, "You are already a member of this group.", false)
                    } else {
                        // Create users <-> groups document
                        createUserGroupsDocument(groupName: groupName){ error in
                            guard error == nil else { return completion(error, nil, false) }
                            guard let currentUser = UserDatabaseService.currentUserProfile else { return completion(error, nil, false) }
                            
                            // Create event
                            let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_JOINED.rawValue, userId: currentUser.userId, username: currentUser.username)
                            EventDatabaseService.createEventDoucment(event: newEvent) { error in
                                guard error == nil else { return completion(error, nil, false) }
                                
                                // Set home group of current user user to this group
                                let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, iconId: currentUser.iconId,  userId: currentUser.userId, username: currentUser.username)
                                UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate, batch: nil) { error, batch in
                                    guard error == nil else { return completion(error, nil, false) }
                                    UserDatabaseService.currentUserProfile? = accountToUpdate
                                    return completion(error, nil, true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Gets all groups for a user.
    static func getAllGroupsForUser(userId: String, completion: @escaping(Error?, [String]) ->()) {
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, []) }
            guard let results = queryResults else { return completion(error, []) }
            
            if !results.documents.isEmpty {
                var groupNames: [String] = []
                for document in results.documents {
                    let data = document.data()
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, groupNames) }
                    groupNames.append(groupName)
                }
                let sortedGroupNames = groupNames.sorted(by: { $0.lowercased() < $1.lowercased() })
                return completion(error, sortedGroupNames)
            }
            // No groups for user
            return completion(error, [])
        }
    }
    
    // Gets all users in a group.
    static func getAllUsersInGroup(groupName: String, completion: @escaping(Error?, [UserGroup]) ->()) {
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, []) }
            guard let results = queryResults else { return completion(error, []) }
            
            if !results.documents.isEmpty {
                var usersInGroup: [UserGroup] = []
                for document in results.documents {
                    let data = document.data()
                    
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, usersInGroup) }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return completion(error, usersInGroup) }
                    guard let pointsInGroup = data[DatabaseField.points.rawValue] as? Double else { return completion(error, usersInGroup) }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, usersInGroup) }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return completion(error, usersInGroup) }
                    
                    usersInGroup.append(UserGroup(groupName: groupName, iconId: iconId, pointsInGroup: pointsInGroup, userId: userId, username: username))
                }
                let sortedUsers = usersInGroup.sorted(by: { $0.pointsInGroup > $1.pointsInGroup })
                return completion(error, sortedUsers)
            }
            // No users found
            return completion(error, [])
        }
    }
    
    // Gets group by name.
    static func getGroupByName(groupName: String, completion: @escaping(Error?, Group) ->()) {
        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, defaultGroup) }
            guard let results = queryResults else { return completion(error, defaultGroup) }
            
            var group: Group = defaultGroup
            if !results.documents.isEmpty {
                for document in results.documents {
                    let data = document.data()
                
                    guard let host = data[DatabaseField.host.rawValue] as? String else { return completion(error, defaultGroup) }
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, defaultGroup) }
                    guard let groupPasscode = data[DatabaseField.group_passcode.rawValue] as? String else { return completion(error, defaultGroup) }
                    
                    group = Group(host: host, groupName: groupName, groupPasscode: groupPasscode)
                }
                return completion(error, group)
            }
            // No group found
            return completion(error, defaultGroup)
        }
    }
    
    static func updateAllUserGroupsDocuments(accountToUpdate: User, batch: WriteBatch, completion: @escaping(Error?, WriteBatch?) ->()) {
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: accountToUpdate.userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, nil) }
            guard let results = queryResults else { return completion(error, nil) }
            
            if !results.documents.isEmpty {
                for document in results.documents {
                    let data = document.data()
                    let docId = document.documentID
                    let docRef = databaseInstance.collection(DatabaseCollection.user_groups.rawValue).document(docId)
                    
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, nil) }
                    guard let pointsInGroup = data[DatabaseField.points.rawValue] as? Double else { return completion(error, nil) }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, nil) }
                    
                    let fields: [AnyHashable : Any] = [
                        DatabaseField.group_name.rawValue: groupName,
                        DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                        DatabaseField.points.rawValue: pointsInGroup,
                        DatabaseField.user_id.rawValue: userId,
                        DatabaseField.username.rawValue: accountToUpdate.username,
                    ]
                    
                    batch.updateData(fields, forDocument: docRef)
                }
                return completion(error, batch)
            }
            // No users found
            return completion(error, batch)
        }
    }

    // Updates userGroups document.
    static func updateUserGroupsDocument(userGroupToUpdate: UserGroup, completion: @escaping(Error?) ->()) {
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userGroupToUpdate.userId)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: userGroupToUpdate.groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error) }
            guard let results = queryResults else { return completion(error) }
                        
            if !results.documents.isEmpty {
                for document in results.documents {
                    let docId = document.documentID
                    let docRef = databaseInstance.collection(DatabaseCollection.user_groups.rawValue).document(docId)
                   
                    docRef.updateData([
                        DatabaseField.group_name.rawValue: userGroupToUpdate.groupName,
                        DatabaseField.icon_id.rawValue: userGroupToUpdate.iconId,
                        DatabaseField.points.rawValue: userGroupToUpdate.pointsInGroup,
                        DatabaseField.user_id.rawValue: userGroupToUpdate.userId,
                        DatabaseField.username.rawValue: userGroupToUpdate.username,
                    ]) { error in
                        guard error == nil else { return completion(error) }
                        // Document updated
                        return completion(error)
                    }
                }
            }
            // No document found
            return completion(error)
        }
    }
}

// Delegate for updating ActivityFeedViewController, HomeViewController, and ManageGroupsViewController after creating/joining a group.
protocol GroupUpdatesDelegate {
    func onGroupUpdates()
}
