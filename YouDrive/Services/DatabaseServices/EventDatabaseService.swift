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

                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return completion(error, []) }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? Int else { return completion(error, []) }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return completion(error, []) }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return completion(error, []) }
                    guard let type = data[DatabaseField.type.rawValue] as? String else { return completion(error, []) }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return completion(error, []) }

                    events.append(Event(groupName: groupName, iconId: iconId, points: points, timestamp: timestamp, type: type, username: username))
                }
                return completion(error, events)
            }
            // No events found
            return completion(error, [])
        }
    }
}

// Delegate for updating ActivityFeedViewController after an event is added.
protocol EventUpdatesDelegate {
    func onEventUpdates()
}

