//
//  EventDatabaseService.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/4/22.
//

import Firebase
import FirebaseAuth
import Foundation

class EventDatabaseService {
    
    static var databaseInstance = Firestore.firestore()
    
    // Adds a document to "events" table.
    static func createEventDoucment(event: Event, completion: @escaping(Error?) ->()) {
        databaseInstance.collection(DatabaseCollection.events.rawValue).addDocument(data: [
            DatabaseField.group_name.rawValue: event.groupName,
            DatabaseField.icon_id.rawValue: event.iconId,
            DatabaseField.points.rawValue: event.points,
            DatabaseField.timestamp.rawValue: event.timestamp,
            DatabaseField.type.rawValue: event.type,
            DatabaseField.user_id.rawValue: event.userId,
            DatabaseField.username.rawValue: event.username,
        ]) { error in
            guard error == nil else { return completion(error) }
            // Successfully added document to "events" table
            return completion(error)
        }
    }
    
    // Gets event documents for a group name.
    static func getEventsForGroup(groupName: String, completion: @escaping(Error?, [Event]) ->()) {
        databaseInstance.collection(DatabaseCollection.events.rawValue)
            .whereField(DatabaseField.group_name.rawValue, isEqualTo: groupName)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error, []) }
            guard let results = queryResults else { return completion(error, []) }
                        
            if !results.documents.isEmpty {
                var events: [Event] = []
                for document in results.documents {
                    let data = document.data()

                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, events) }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return completion(error, events) }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return completion(error, events) }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return completion(error, events) }
                    guard let type = data[DatabaseField.type.rawValue] as? String else { return completion(error, events) }
                    guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return completion(error, events) }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return completion(error, events) }

                    events.append(Event(groupName: groupName, iconId: iconId, points: points, timestamp: timestamp, type: type, userId: userId, username: username))
                }
                return completion(error, events)
            }
            // No events found
            return completion(error, [])
        }
    }
    
    static func updateAllEventsForUser(accountToUpdate: User, batch: WriteBatch, completion: @escaping(Error?) ->()) {
        databaseInstance.collection(DatabaseCollection.events.rawValue)
            .whereField(DatabaseField.user_id.rawValue, isEqualTo: accountToUpdate.userId)
            .getDocuments()
        {(queryResults, error) in
            guard error == nil else { return completion(error) }
            guard let results = queryResults else { return completion(error) }
            
            if !results.documents.isEmpty {
                updateEventsAndCommitBatch(accountToUpdate: accountToUpdate, documents: results.documents, batch: batch)
                return completion(error)
            }
            // No events found, commit batch
            commitBatch(batch: batch)
            return completion(error)
        }
    }
    
    private static func updateEventsAndCommitBatch(accountToUpdate: User, documents: [QueryDocumentSnapshot], batch: WriteBatch) {
        for document in documents {
            let data = document.data()
            let docId = document.documentID
            let docRef = databaseInstance.collection(DatabaseCollection.events.rawValue).document(docId)
            
            guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
            guard let points = data[DatabaseField.points.rawValue] as? Double else { return }
            guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return }
            guard let type = data[DatabaseField.type.rawValue] as? String else { return }
            guard let userId = data[DatabaseField.user_id.rawValue] as? String else { return }
            
            let fields: [AnyHashable : Any] = [
                DatabaseField.group_name.rawValue: groupName,
                DatabaseField.icon_id.rawValue: accountToUpdate.iconId,
                DatabaseField.points.rawValue: points,
                DatabaseField.timestamp.rawValue: timestamp,
                DatabaseField.type.rawValue: type,
                DatabaseField.user_id.rawValue: userId,
                DatabaseField.username.rawValue: accountToUpdate.username,
            ]
            
            batch.updateData(fields, forDocument: docRef)
        }
        commitBatch(batch: batch)
    }
    
    private static func commitBatch(batch: WriteBatch) {
        batch.commit() { error in
            guard error == nil else { return }
            AccountViewController.accountUpdatesDelegate?.onAccountUpdated()
            ActivityFeedViewController.accountUpdatesDelegate?.onAccountUpdated()
            HomeViewController.accountUpdatesDelegate?.onAccountUpdated()
            return
        }
    }
}

// Delegate for updating ActivityFeedViewController after an event is added.
protocol EventUpdatesDelegate {
    func onEventUpdates()
}

