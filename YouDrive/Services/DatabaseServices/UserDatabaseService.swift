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
        
    static var currentUserProfile:User?
    static var databaseInstance = Firestore.firestore()
    static var driversForHomeGroup: [UserGroup] = []
    static var groupsForCurrentUser: [String] = []
    static var hasReachedMaxGroups = false
    
    static let defaultUserObject = User(email: "", homeGroup: "", iconId: 2, userId: "", username: "")

    // Creates user account with Firebase.
    static func createUserAccount(accountToCreate: User, password: String, completion: @escaping(Error?) ->()) {
        Auth.auth().createUser(withEmail: accountToCreate.email, password: password) { user, error in
            guard error == nil else { return completion(error) }
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else { return completion(error) }
            guard let userId = currentUser?.uid else { return completion(error) }
            
            accountToCreate.userId = userId
            currentUserProfile = accountToCreate
            
            guard let currentUser = currentUserProfile else { return completion(error) }
            createUserDoucment(user: currentUser){ error in
                guard error == nil else { return completion(error) }
                // Created user document
                return completion(error)
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
            guard error == nil else { return completion(error) }
            // Successfully added document to "users" table
            return completion(error)
        }
    }
    
    // Edits all documents related to the passed in account.
    static func editUser(accountToUpdate: User, completion: @escaping(Error?) ->()) {
        let batch1 = databaseInstance.batch()

        UserDatabaseService.updateUserDocument(accountToUpdate: accountToUpdate, batch: batch1) { error, writeBatchAccount in
            guard error == nil else { return completion(error) }
            guard let batch2 = writeBatchAccount else { return completion(error) }

            GroupDatabaseService.updateAllUserGroupsDocuments(accountToUpdate: accountToUpdate, batch: batch2) { error, writeBatchGroups in
                guard error == nil else { return completion(error) }
                guard let batch3 = writeBatchGroups else { return completion(error) }

                DriveDatabaseService.updateAllDrivesForUser(accountToUpdate: accountToUpdate, batch: batch3) { error, writeBatchDrives in
                    guard error == nil else { return completion(error) }
                    guard let batch4 = writeBatchDrives else { return completion(error) }

                    EventDatabaseService.updateAllEventsForUser(accountToUpdate: accountToUpdate, batch: batch4) { error in
                        guard error == nil else { return completion(error) }
                        return completion(error)
                    }
                }
            }
        }
    }
    
    // Sends password recovery email.
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           return completion(error)
        }
    }
    
    // Signs in user with Firebase.
    static func handleSignIn(email: String, password: String, completion: @escaping(Error?, User) ->()) {
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            guard error == nil else { return completion(error, defaultUserObject) }
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else { return }
            guard let userId = currentUser?.uid else { return }

            getUserDocument(userId: userId) { error, currentUser in
                guard error == nil else { return completion(error, defaultUserObject) }
                currentUserProfile = currentUser
                ActivityFeedViewController.accountUpdatesDelegate?.onAccountUpdated()
                return completion(error, currentUser)
            }
        }
    }
    
    // Signs out current user.
    static func handleSignOut() {
        let currentUser = Auth.auth().currentUser
        guard currentUser != nil else { return }
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("Unable to sign out with FirebaseAuth.")
            return
        }
        
        currentUserProfile = nil
        driversForHomeGroup = []
        groupsForCurrentUser = []
        
        NavigationService.showSignInViewController()
    }
    
    
    // Gets a user document.
    static func getUserDocument(userId: String, completion: @escaping(Error?, User) ->()) {
        databaseInstance.collection(DatabaseCollection.users.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, self.defaultUserObject) }
            guard let results = queryResults else { return completion(error, defaultUserObject) }
            
            var user = defaultUserObject
            if !results.documents.isEmpty {
                for document in results.documents {
                    let data = document.data()
                    
                    guard let email = data[DatabaseField.email.rawValue] as? String else { return completion(error, self.defaultUserObject) }
                    guard let homeGroup = data[DatabaseField.home_group.rawValue] as? String else { return completion(error, self.defaultUserObject) }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return completion(error, self.defaultUserObject) }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, self.defaultUserObject) }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return completion(error, self.defaultUserObject) }
                    
                    user = User(email: email, homeGroup: homeGroup, iconId: iconId, userId: userId, username: username)
                }
                // User document found
                return completion(error, user)
            }
            // No document found
            return completion(error, defaultUserObject)
        }
    }
    
    // Updates user document.
    static func updateUserDocument(accountToUpdate: User, batch: WriteBatch?, completion: @escaping(Error?, WriteBatch?) ->()) {
        databaseInstance.collection(DatabaseCollection.users.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: accountToUpdate.userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, nil) }
            guard let results = queryResults else { return completion(error, nil) }
                        
            if !results.documents.isEmpty {
                guard let document = results.documents.first else { return completion(error, nil) }
                let docId = document.documentID
                let docRef =  databaseInstance.collection(DatabaseCollection.users.rawValue).document(docId)
               
                if batch != nil {
                    guard let writeBatch = batch else { return completion(error, nil) }
                    writeBatch.updateData([
                        DatabaseField.email.rawValue: accountToUpdate.email,
                        DatabaseField.home_group.rawValue: accountToUpdate.homeGroup,
                        DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                        DatabaseField.user_id.rawValue: accountToUpdate.userId,
                        DatabaseField.username.rawValue: accountToUpdate.username,
                    ], forDocument: docRef)
                    return completion(error, writeBatch)
                }
                
                docRef.updateData([
                    DatabaseField.email.rawValue: accountToUpdate.email,
                    DatabaseField.home_group.rawValue: accountToUpdate.homeGroup,
                    DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                    DatabaseField.user_id.rawValue: accountToUpdate.userId,
                    DatabaseField.username.rawValue: accountToUpdate.username,
                ]) { error in
                    guard error == nil else { return completion(error, nil) }

                    if accountToUpdate.userId == currentUserProfile?.userId {
                        currentUserProfile = accountToUpdate
                    }
                    // Document updated
                    return completion(error, nil)
                }
            }
            // No document found to update
            return completion(error, nil)
        }
    }
}

// Reload data when account is updated.
protocol AccountUpdatesDelegate {
    func onAccountUpdated()
}
