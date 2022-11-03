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

    // Helper func to check if group credentials match a database document.
    private static func checkIfGroupCredentialsMatch(groupName: String, groupPasscode: String, completion: @escaping(Error?, Bool) ->()) {
        
        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.group_passcode.rawValue, isEqualTo: groupPasscode)
            .getDocuments()
        { (queryResults, error) in

            guard error == nil else {
                completion(error, false)
                return
            }
                
            guard let results = queryResults else {
                completion(error, false)
                return
            }
            
            if !results.documents.isEmpty {
                // Group credentials match
                completion(error, true)
            } else {
                // No group exists with those credentials
                completion(error, false)
            }
        }
    }
    
    // Helper func to check if group name already exists in database.
    private static func checkIfGroupNameExists(groupName: String, completion: @escaping(Error?, String?) ->()) {

        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error, nil)
                return
            }
            
            guard let results = queryResults else {
                completion(error, nil)
                return
            }
                
            if !results.documents.isEmpty {
                // Group already exists
                completion(error, "Group name already exists, try again.")
            } else {
                // No group exists
                completion(error, nil)
            }
        }
    }
    
    // Helper func to check if user is already a member of a group.
    private static func checkIfUserIsMemberOfGroup(groupName: String, completion: @escaping(Error?, Bool) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: currentUser.userId)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error, false)
                return
            }
                
            guard let results = queryResults else {
                completion(error, false)
                return
            }
            
            if !results.documents.isEmpty {
                // User is already a member of this group
                completion(error, true)
            } else {
                // User is not a member of this group
                completion(error, false)
            }
        }
    }
    
    // Creates new group with current user as host.
    static func createNewGroup(groupName: String, groupPasscode: String, completion: @escaping(Error?, String?) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        // Check if group name exists already
        checkIfGroupNameExists(groupName: groupName){ error, errorMessage in
            guard error == nil else {
                completion(error, nil)
                return
            }
            
            guard errorMessage == nil else {
                // Group name already exists, return with error message
                completion(error, errorMessage)
                return
            }
            
            // Since no group exists with this name, create new group
            createNewGroupDocument(groupName: groupName, groupPasscode: groupPasscode) { error in
                guard error == nil else {
                    completion(error, nil)
                    return
                }
                
                // Create users <-> groups document
                createUserGroupsDocument(groupName: groupName){ error in
                    guard error == nil else {
                        completion(error, nil)
                        return
                    }
                    
                    // Create event
                    let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_CREATED.rawValue, username: currentUser.username)
                    EventDatabaseService.createEventDoucment(event: newEvent) { error in
                        
                        guard error == nil else {
                            completion(error, nil)
                            return
                        }
                        
                        // Set home group of current user user to this group
                        let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, iconId: currentUser.iconId,  userId: currentUser.userId, username: currentUser.username)
                        UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate) { error in
                            
                            guard error == nil else {
                                completion(error, nil)
                                return
                            }
                            
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
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        databaseInstance.collection(DatabaseCollection.groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.group_passcode.rawValue: groupPasscode,
            DatabaseField.host.rawValue: currentUser.userId
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            // Successfully added document to "groups" table
            return completion(error)
        }
    }
    
    // Helper func to add a document to "userGroups" table.
    private static func createUserGroupsDocument(groupName: String, completion: @escaping(Error?) ->()) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.icon_id.rawValue: currentUser.iconId,
            DatabaseField.points.rawValue: "0.0",
            DatabaseField.user_id.rawValue: currentUser.userId,
            DatabaseField.username.rawValue: currentUser.username
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added doument to "user_groups" table
            completion(error)
        }
    }
    
    // Deletes userGroups document.
    static func deleteUserGroupsDocument(groupName: String, userId: String, completion: @escaping(Error?) ->()) {
        
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error)
                return
            }
                
            guard let results = queryResults else {
                completion(error)
                return
            }
                        
            if !results.documents.isEmpty {
                
                guard let document = results.documents.first else { return }
                let docId = document.documentID
                
                databaseInstance.collection(DatabaseCollection.user_groups.rawValue).document(docId).delete() { error in
                                        
                    guard error == nil else {
                        completion(error)
                        return
                    }
                                        
                    ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
                    HomeViewController.groupUpdatesDelegate?.onGroupUpdates()
                    
                    guard let currentUser = UserDatabaseService.currentUserProfile else { return }
                    
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
                        let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_LEFT.rawValue, username: currentUser.username)
                        EventDatabaseService.createEventDoucment(event: newEvent) { error in
                            guard error == nil else {
                                completion(error)
                                return
                            }
                            
                            UserDatabaseService.updateUserDocument(accountToUpdate: updatedUser) { error in
                                guard error == nil else {
                                    completion(error)
                                    return
                                }
                                
                                guard UserDatabaseService.groupsForCurrentUser.count > 1 else {
                                    
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    let viewController = storyboard.instantiateViewController(withIdentifier: "NoGroupsViewController") as? NoGroupsViewController
                                    UIApplication.shared.windows.first?.rootViewController = viewController
                                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                                    
                                    completion(error)
                                    return
                                }
                                // Successfully deleted and updated home group for current user
                                return completion(error)
                            }
                        }
                    }
                    // Successfully deleted
                    return completion(error)
                }
            }
            // No document found
            completion(error)
        }
    }
    
    // Joins existing group.
    static func joinGroup(groupName: String, groupPasscode: String, completion: @escaping(Error?, String?, Bool) ->()) {
        // Check if group credentials match a database record
        checkIfGroupCredentialsMatch(groupName: groupName, groupPasscode: groupPasscode) { error, doCredentialsMatch in
            guard error == nil else {
                completion(error, nil, false)
                return
            }
            
            if !doCredentialsMatch {
                // Credentials don't match
                return completion(error, nil, false)
            } else {
                // Check is user is already a member of this group
                checkIfUserIsMemberOfGroup(groupName: groupName){ error, isUserMemberInGroup in
                    guard error == nil else {
                        completion(error, nil, false)
                        return
                    }
                    
                    if isUserMemberInGroup {
                        return completion(error, "You are already a member of this group.", false)
                    } else {
                        // Create users <-> groups document
                        createUserGroupsDocument(groupName: groupName){ error in
                            guard error == nil else {
                                completion(error, nil, false)
                                return
                            }
                            
                            guard let currentUser = UserDatabaseService.currentUserProfile else { return }
                            
                            // Create event
                            let newEvent = Event(groupName: groupName, iconId: currentUser.iconId, points: 0.0, timestamp: Date().timeIntervalSince1970.description, type: EventType.GROUP_JOINED.rawValue, username: currentUser.username)
                            
                            EventDatabaseService.createEventDoucment(event: newEvent) { error in
                                guard error == nil else {
                                    completion(error, nil, false)
                                    return
                                }
                                
                                // Set home group of current user user to this group
                                let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, iconId: currentUser.iconId,  userId: currentUser.userId, username: currentUser.username)
                                
                                UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate) { error in
                                    guard error == nil else {
                                        completion(error, nil, false)
                                        return
                                    }
                                    
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

            guard error == nil else {
                completion(error, [])
                return
            }
                            
            guard let results = queryResults else {
                completion(error, [])
                return
            }
            
            if !results.documents.isEmpty {
                
                var groupNames: [String] = []
                for document in results.documents {
                    let data = document.data()
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
                    groupNames.append(groupName)
                }
                
                let sortedGroupNames = groupNames.sorted(by: { $0 < $1 })
                return completion(error, sortedGroupNames)
            }
            
            // No groups for user
            completion(error, [])
        }
    }
    
    // Gets all users in a group.
    static func getAllUsersInGroup(groupName: String, completion: @escaping(Error?, [UserGroup]) ->()) {

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
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
                
                var usersInGroup: [UserGroup] = []
                
                for document in results.documents {
                    
                    let data = document.data()
                    
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? String else { return }
                    guard let pointsInGroup = data[DatabaseField.points.rawValue] as? String else { return }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return }
                    
                    usersInGroup.append(UserGroup(groupName: groupName, iconId: iconId, pointsInGroup: pointsInGroup, userId: userId, username: username))
                }
                
                let sortedUsers = usersInGroup.sorted(by: { Double($0.pointsInGroup) ?? 0.0 > Double($1.pointsInGroup) ?? 0.0 })
                
                return completion(error, sortedUsers)
            }
            
            // No users found
            completion(error, [])
        }
    }
    
    // Gets group by name.
    static func getGroupByName(groupName: String, completion: @escaping(Error?, Group) ->()) {
        let defaultGroup = Group(host: "", groupName: "", groupPasscode: "")
        
        databaseInstance.collection(DatabaseCollection.groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error, defaultGroup)
                return
            }
            
            guard let results = queryResults else {
                completion(error, defaultGroup)
                return
            }
            
            var group: Group = defaultGroup

            if !results.documents.isEmpty {
                
                for document in results.documents {
                    
                    let data = document.data()
                
                    guard let host = data[DatabaseField.host.rawValue] as? String else { return }
                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
                    guard let groupPasscode = data[DatabaseField.group_passcode.rawValue] as? String else { return }
                    
                    group = Group(host: host, groupName: groupName, groupPasscode: groupPasscode)
                }
                
                return completion(error, group)
            }
            
            // No group found
            completion(error, defaultGroup)
        }
    }
    
    // Updates userGroups document.
    static func updateUserGroupsDocument(userGroupToUpdate: UserGroup, completion: @escaping(Error?) ->()) {
        
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userGroupToUpdate.userId)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: userGroupToUpdate.groupName)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error)
                return
            }
                
            guard let results = queryResults else {
                completion(error)
                return
            }
                        
            if !results.documents.isEmpty {
                
                for document in results.documents {
                    
                    let docId = document.documentID
                    let docRef =  databaseInstance.collection(DatabaseCollection.user_groups.rawValue).document(docId)
                   
                    docRef.updateData([
                        DatabaseField.group_name.rawValue: userGroupToUpdate.groupName,
                        DatabaseField.icon_id.rawValue: userGroupToUpdate.iconId,
                        DatabaseField.points.rawValue: userGroupToUpdate.pointsInGroup,
                        DatabaseField.user_id.rawValue: userGroupToUpdate.userId,
                        DatabaseField.username.rawValue: userGroupToUpdate.username,
                    ]) { error in
                        
                        guard error == nil else {
                            completion(error)
                            return
                        }
                        
                        // Document updated
                        return completion(error)
                    }
                }
            }
            // No document found
            completion(error)
        }
    }
}

// Delegate for updating HomeViewCcontroller after creating/joining a group.
protocol GroupUpdatesDelegate {
    func onGroupUpdates()
}
