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

class DatabaseService {
    
    private static var currentUserProfile:User?
    private static var databaseInstance = Firestore.firestore()
    
    // Return DatabaseService.currentUserProfile or get current user from Firebase
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

    // Sign in user with Firebase
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
    
    // Create user account with Firebase
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
    
    // Sign out current user
    static func handleSignOut() {
        
        let currentUser = Auth.auth().currentUser
        guard currentUser != nil else {
            return
        }
        
        try! Auth.auth().signOut()
        currentUserProfile = nil
    }
    
    // Send password recovery email
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           completion(error)
        }
    }
    
    // Create new group with current user as host
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
    
    // Join existing group
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
    
    // Check if group credentials match a database record
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
    
    // Helper func to check group name already exists in database
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
    
    // Helper func to check if user is already a member of a group
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
    
    // Helper func to add new group to database
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
    
    // Helper func to add document to userGroups table
    private static func createUserGroupsDocument(groupName: String, completion: @escaping(Error?) ->()) {

        databaseInstance.collection(DatabaseCollection.user_groups.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: groupName,
            DatabaseField.points.rawValue: 0,
            DatabaseField.user_id.rawValue: (currentUserProfile?.userID ?? "") as String
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            //Successfully added doument to "user_groups" table
            completion(error)
        }
    }
}
