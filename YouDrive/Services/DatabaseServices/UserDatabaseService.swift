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
    static var driversForHomeGroup: [UserGroup] = []
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
            
            guard let currentUser = currentUserProfile else { return }
            
            createUserDoucment(user: currentUser){ error in
                
                guard error == nil else {
                    return
                }
            
                completion(error)
            }
        }
    }
    
    // Adds a document to "users" table.
    static func createUserDoucment(user: User, completion: @escaping(Error?) ->()) {
             
        databaseInstance.collection(DatabaseCollection.users.rawValue).addDocument(data: [
            DatabaseField.email.rawValue: user.email,
            DatabaseField.home_group.rawValue: user.homeGroup,
            DatabaseField.icon_id.rawValue: user.iconId,
            DatabaseField.user_id.rawValue: user.userId,
            DatabaseField.username.rawValue: user.username,
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
        
        let defaultUserObject = User(email: "", homeGroup: "", iconId: "", userId: "", username: "")

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
        driversForHomeGroup = []
        groupsForCurrentUser = []
        SideMenuTableViewController.selectedRow = 0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    
    // Gets a user document.
    static func getUserDocument(userId: String, completion: @escaping(Error?, User) ->()) {
        
        let defaultUserObject = User(email: "", homeGroup: "", iconId: "",  userId: "", username: "")
        
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

                    guard let email = data[DatabaseField.email.rawValue] as? String else { return }
                    guard let homeGroup = data[DatabaseField.home_group.rawValue] as? String else { return }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? String else { return }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return }
                    
                    user = User(email: email, homeGroup: homeGroup, iconId: iconId, userId: userId, username: username)
                }
                
                return completion(error, user)
            }
            
            // No document found
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
                
                guard let document = results.documents.first else { return }
                let docId = document.documentID
                let docRef =  databaseInstance.collection(DatabaseCollection.users.rawValue).document(docId)
               
                docRef.updateData([
                    DatabaseField.email.rawValue: accountToUpdate.email,
                    DatabaseField.home_group.rawValue: accountToUpdate.homeGroup,
                    DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                    DatabaseField.user_id.rawValue: accountToUpdate.userId,
                    DatabaseField.username.rawValue: accountToUpdate.username,
                ]) { error in
                    
                    guard error == nil else {
                        completion(error)
                        return
                    }
                    
                    if accountToUpdate.userId == currentUserProfile?.userId {
                        currentUserProfile = accountToUpdate
                    }
                    
                    // Document updated
                    completion(error)
                }
            }
            // No document found to update
            completion(error)
        }
    }
}
