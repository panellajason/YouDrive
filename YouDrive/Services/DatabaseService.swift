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
    
    private static var databaseInstance = Firestore.firestore()
    private static var currentUserProfile:User?
    
    // Return DatabaseService.currentUserProfile or get current user from Firebase
    static func getCurrentUser() -> User? {
        
        guard DatabaseService.currentUserProfile != nil else {
            let currentUser = Auth.auth().currentUser
            guard currentUser != nil else {
                return nil
            }
            
            // Return rando id if id can't found (shouldn't ever happen)
            currentUserProfile = User(userID: currentUser?.uid ?? UUID().uuidString)
            return currentUserProfile
        }
        
        return DatabaseService.getCurrentUser()
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
        DatabaseService.currentUserProfile = nil
    }
    
    // Send password recovery email
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           completion(error)
        }
    }
    
}
