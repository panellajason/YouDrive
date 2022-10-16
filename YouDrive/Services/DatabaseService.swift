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
    static var currentUserProfile:User?

    static func handleSignIn(email: String, password: String, completion: @escaping(Error?) ->()) {
        
        Auth.auth().signIn(withEmail: email, password: password) { user, error in

            guard error == nil && user != nil else {
                completion(error)
                return
            }
            
            guard let userID = Auth.auth().currentUser?.uid else { return }
            currentUserProfile = User(userID: userID, favoriteTours: [])
            completion(error)
        }
    }
    
    static func handleSignUp(email: String, password: String, completion: @escaping(Error?) ->()) {
        
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            
            guard error == nil && user != nil else {
                completion(error)
                return
            }
            
            guard let userID = Auth.auth().currentUser?.uid else { return }
            currentUserProfile = User(userID: userID, favoriteTours: [])
            completion(error)
        }
    }
    
    static func handlePasswordRecoveryEmail (email: String, completion: @escaping(Error?) ->()) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
           completion(error)
        }
    }
    
}
