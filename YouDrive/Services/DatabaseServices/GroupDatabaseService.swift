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
        
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: (UserDatabaseService.currentUserProfile?.userId ?? "") as String)
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
                    
                    guard let currentUser = UserDatabaseService.currentUserProfile else { return }
                    
                    // Set home group of current user user to this group
                    let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, userId: currentUser.userId, username: currentUser.username)
                    UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate) { error in
                        
                        guard error == nil else {
                            completion(error, nil)
                            return
                        }
                        
                        completion(error, nil)
                    }
                }
            }
        }
    }
    
    // Helper func to add a document to "groups" table.
    private static func createNewGroupDocument(groupName: String, groupPasscode: String, completion: @escaping(Error?) ->()) {
        
        databaseInstance.collection(DatabaseCollection.groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.group_passcode.rawValue: groupPasscode,
            DatabaseField.host.rawValue: (UserDatabaseService.currentUserProfile?.userId ?? "") as String
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added document to "groups" table
            completion(error)
        }
    }
    
    // Helper func to add a document to "userGroups" table.
    private static func createUserGroupsDocument(groupName: String, completion: @escaping(Error?) ->()) {

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.points.rawValue: "0",
            DatabaseField.user_id.rawValue: (UserDatabaseService.currentUserProfile?.userId ?? "") as String,
            DatabaseField.username.rawValue: UserDatabaseService.currentUserProfile?.username ?? ""
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added doument to "user_groups" table
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
                completion(error, nil, false)
            } else {
                
                // Check is user is already a member of this group
                checkIfUserIsMemberOfGroup(groupName: groupName){ error, isUserMemberInGroup in
                    
                    guard error == nil else {
                        completion(error, nil, false)
                        return
                    }
                    
                    if isUserMemberInGroup {
                        completion(error, "You are already a member of this group.", false)
                    } else {
                        
                        // Create users <-> groups document
                        createUserGroupsDocument(groupName: groupName){ error in
                            
                            guard error == nil else {
                                completion(error, nil, false)
                                return
                            }
                            
                            guard let currentUser = UserDatabaseService.currentUserProfile else { return }
                            
                            // Set home group of current user user to this group
                            let accountToUpdate = User(email: currentUser.email, homeGroup: groupName, userId: currentUser.userId, username: currentUser.username)
                            UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate) { error in
                                
                                guard error == nil else {
                                    completion(error, nil, false)
                                    return
                                }
                                
                                completion(error, nil, true)
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
                    let groupName = data[DatabaseField.group_name.rawValue] as? String ?? ""
                    
                    groupNames.append(groupName)
                }
                
                UserDatabaseService.groupsForCurrentUser = groupNames

                return completion(error, groupNames)
            }
            
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
                    let groupName = data[DatabaseField.group_name.rawValue] as? String ?? ""
                    let pointsInGroup = data[DatabaseField.points.rawValue] as? String ?? ""
                    let userId = data[DatabaseField.user_id.rawValue] as? String ?? ""
                    let username = data[DatabaseField.username.rawValue] as? String ?? ""
                    usersInGroup.append(UserGroup(groupName: groupName, pointsInGroup: pointsInGroup, userId: userId, username: username))
                }
                
                return completion(error, usersInGroup)
            }
            
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
                    let host = data[DatabaseField.host.rawValue] as? String ?? ""
                    let groupName = data[DatabaseField.group_name.rawValue] as? String ?? ""
                    let groupPasscode = data[DatabaseField.group_passcode.rawValue] as? String ?? ""
                    group = Group(host: host, groupName: groupName, groupPasscode: groupPasscode)
                }
                
                return completion(error, group)
            }
            
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
                        DatabaseField.points.rawValue: userGroupToUpdate.pointsInGroup,
                        DatabaseField.user_id.rawValue: userGroupToUpdate.userId,
                        DatabaseField.username.rawValue: userGroupToUpdate.username,
                    ]) { error in
                        
                        guard error == nil else {
                            completion(error)
                            return
                        }
                        
                        // Document updated
                        completion(error)
                    }
                }
            }
        }
    }
}


