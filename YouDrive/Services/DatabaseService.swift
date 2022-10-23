//
//  DatabaseService.swift
//  BCLog
//
//  Created by Jason Panella on 8/11/21.
//  Copyright © 2021 Jason Panella. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import MapKit

class DatabaseService {
    
    private static var currentUserProfile:User?
    private static var databaseInstance = Firestore.firestore()
    
    // Returns DatabaseService.currentUserProfile or gets current user from Firebase.
    static func getCurrentUser() -> User? {
        
        guard currentUserProfile != nil else {
            
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else { return nil }
            
            guard let userId = currentUser?.uid else { return nil }
            
            currentUserProfile = User(userID: userId)
            return currentUserProfile
        }
        
        return currentUserProfile
    }

    // Signs in user with Firebase.
    static func handleSignIn(email: String, password: String, completion: @escaping(Error?) ->()) {
        
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            guard error == nil && user != nil else {
                completion(error)
                return
            }
            
            guard let userID = Auth.auth().currentUser?.uid else { return }
            currentUserProfile = User(userID: userID)
            // Signed in
            completion(error)
        }
    }
    
    // Creates user account with Firebase.
    static func createUserAccount(email: String, password: String, completion: @escaping(Error?) ->()) {
        
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            guard error == nil && user != nil else {
                completion(error)
                return
            }
            
            guard let userID = Auth.auth().currentUser?.uid else { return }
            currentUserProfile = User(userID: userID)
            // Account created
            completion(error)
        }
    }
    
    // Signs out current user.
    static func handleSignOut() {
        
        let currentUser = Auth.auth().currentUser
        guard currentUser != nil else {
            return
        }
        
        try! Auth.auth().signOut()
        currentUserProfile = nil
    }
    
    // Sends password recovery email
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           completion(error)
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
                    completion(error, nil)
                }
            }
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
                            
                            completion(error, nil, true)
                        }
                    }
                }
            }
        }
    }
    
    // Adds a document to "drives" table.
    static func addDriveToGroup(amount: String, distance: String, groupName: String, location: String, numberOfPassengers: String, whoPaid: String, completion: @escaping(Error?) ->()) {
     
        databaseInstance.collection(DatabaseCollection.drives.rawValue).addDocument(data: [
            DatabaseField.amount.rawValue: amount,
            DatabaseField.distance.rawValue: distance,
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.location.rawValue: location,
            DatabaseField.number_of_passengers.rawValue: numberOfPassengers,
            DatabaseField.user_id.rawValue: (currentUserProfile?.userID ?? "") as String,
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
    
    
    // Checks if user is a member of ANY group.
     static func checkIfUserIsMemberOfAnyGroup(completion: @escaping(Error?, Bool) ->()) {
        
        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: (currentUserProfile?.userID ?? "") as String)
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
                // User is a member of a group
                completion(error, true)
            } else {
                // User is not a member in any group
                completion(error, false)
            }
        }
    }
    
    // Gets all groups for the current user.
     static func getAllGroupsForUser(completion: @escaping(Error?, [String]) ->()) {

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: (currentUserProfile?.userID ?? "") as String)
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
                
                return completion(error, groupNames)
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
                    let userName = data[DatabaseField.user_id.rawValue] as? String ?? ""
                    let userInGroup = UserGroup(groupName: groupName, pointsInGroup: pointsInGroup, userName: userName)
                    usersInGroup.append(userInGroup)
                }
                
                return completion(error, usersInGroup)
            }
            completion(error, [])
        }
    }
    
    
    
    // -------------------------------------------------------- Private functions below --------------------------------------------------------
    
    
    
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
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: (currentUserProfile?.userID ?? "") as String)
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
    
    // Helper func to add a document to "groups" table.
    private static func createNewGroupDocument(groupName: String, groupPasscode: String, completion: @escaping(Error?) ->()) {
        
        databaseInstance.collection(DatabaseCollection.groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.group_passcode.rawValue: groupPasscode,
            DatabaseField.host.rawValue: (currentUserProfile?.userID ?? "") as String
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
            DatabaseField.user_id.rawValue: (currentUserProfile?.userID ?? "") as String
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added doument to "user_groups" table
            completion(error)
        }
    }
}
