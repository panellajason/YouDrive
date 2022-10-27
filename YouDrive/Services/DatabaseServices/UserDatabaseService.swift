//
//  UserDatabaseService.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/24/22.
//

import Foundation
import Firebase
import FirebaseAuth

class UserDatabaseService {
    
    static var databaseInstance = Firestore.firestore()
    
    static var currentUserProfile:User?
    static var groupsForCurrentUser: [String] = []
    
    // Creates user account with Firebase.
    static func createUserAccount(accountToCreate: User, password: String, completion: @escaping(Error?) ->()) {
        
        Auth.auth().createUser(withEmail: accountToCreate.email, password: password) { user, error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else { return }
            guard let userId = currentUser?.uid else { return }
            
            accountToCreate.userId = userId
            currentUserProfile = accountToCreate
            
            createUserDoucment(
                email: accountToCreate.email,
                homeGroup: accountToCreate.homeGroup,
                username: accountToCreate.username
            ){ error in
                
                guard error == nil else {
                    return
                }
            
                completion(error)
            }
        }
    }
    
    // Adds a document to "users" table.
    static func createUserDoucment(email: String, homeGroup: String, username: String, completion: @escaping(Error?) ->()) {
     
        databaseInstance.collection(DatabaseCollection.users.rawValue).addDocument(data: [
            DatabaseField.email.rawValue: email,
            DatabaseField.home_group.rawValue: homeGroup,
            DatabaseField.user_id.rawValue: (currentUserProfile?.userId ?? "") as String,
            DatabaseField.username.rawValue: username,
        ]) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // Successfully added document to "users" table
            completion(error)
        }
    }
    
    // Sends password recovery email.
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           completion(error)
        }
    }
    
    // Signs in user with Firebase.
    static func handleSignIn(email: String, password: String, completion: @escaping(Error?, User) ->()) {
        
        let defaultUserObject = User(email: "", homeGroup: "", userId: "", username: "")

        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            
            guard error == nil else {
                completion(error, defaultUserObject)
                return
            }
            
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else { return }
            guard let userId = currentUser?.uid else { return }

            getUserDocument(userId: userId) { error, currentUser in
                
                guard error == nil else {
                    completion(error, defaultUserObject)
                    return
                }
                
                currentUserProfile = currentUser
                completion(error, currentUser)
            }
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
    
    
    // Gets a user document.
    static func getUserDocument(userId: String, completion: @escaping(Error?, User) ->()) {
        
        let defaultUserObject = User(email: "", homeGroup: "", userId: "", username: "")
        
        databaseInstance.collection(DatabaseCollection.users.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in

            guard error == nil else {
                completion(error, defaultUserObject)
                return
            }
                
            guard let results = queryResults else {
                completion(error, defaultUserObject)
                return
            }
            
            var user = defaultUserObject
            
            if !results.documents.isEmpty {
                
                for document in results.documents {
                    let data = document.data()
                    let email = data[DatabaseField.email.rawValue] as? String ?? ""
                    let hostGroup = data[DatabaseField.home_group.rawValue] as? String ?? ""
                    let userId = data[DatabaseField.user_id.rawValue] as? String ?? ""
                    let username = data[DatabaseField.username.rawValue] as? String ?? ""
                    user = User(email: email, homeGroup: hostGroup, userId: userId, username: username)
                }
                
                return completion(error, user)
            }
            
            completion(error, defaultUserObject)
        }
    }
    
    // Updates user document.
    static func updateUserDocument(accountToUpdate: User, completion: @escaping(Error?) ->()) {
        
        databaseInstance.collection(DatabaseCollection.users.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: accountToUpdate.userId)
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
                    let docRef =  databaseInstance.collection(DatabaseCollection.users.rawValue).document(docId)
                   
                    docRef.updateData([
                        DatabaseField.email.rawValue: accountToUpdate.email,
                        DatabaseField.home_group.rawValue: accountToUpdate.homeGroup,
                        DatabaseField.user_id.rawValue: accountToUpdate.userId,
                        DatabaseField.username.rawValue: accountToUpdate.username,
                    ]) { error in
                        
                        guard error == nil else {
                            completion(error)
                            return
                        }
                        
                        // Document updated
                        currentUserProfile = accountToUpdate
                        completion(error)
                    }
                }
            }
            completion(error)
        }
    }
}
