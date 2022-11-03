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
            
            guard error == nil else {
                completion(error)
                return
            }
            
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

            guard error == nil else {
                completion(error, [])
                return
            }
                
            guard let results = queryResults else {
                completion(error, [])
                return
            }
                        
            if !results.documents.isEmpty {
                
                var events: [Event] = []
                
                for document in results.documents {
                    
                    let data = document.data()

                    guard let groupName = data[DatabaseField.group_name.rawValue] as? String else { return }
                    guard let iconId = data[DatabaseField.icon_id.rawValue] as? String else { return }
                    guard let points = data[DatabaseField.points.rawValue] as? Double else { return }
                    guard let timestamp = data[DatabaseField.timestamp.rawValue] as? String else { return }
                    guard let type = data[DatabaseField.type.rawValue] as? String else { return }
                    guard let username = data[DatabaseField.username.rawValue] as? String else { return }

                    events.append(Event(groupName: groupName, iconId: iconId, points: points, timestamp: timestamp, type: type, username: username))
                }
                
                return completion(error, events)
            }
            
            // No document found
            return completion(error, [])
        }
    }
}

// Delegate for updating ActivityFeedViewCcontroller after an event is added a group.
protocol EventUpdatesDelegate {
    func onEventUpdates()
}

