//
//  Event.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/4/22.
//

import Foundation

// Object for defining an activity feed event.
class Event {
    var groupName: String
    var iconId: Int
    var points: Double
    var timestamp: String
    var type: String
    var userId: String
    var username: String

    init(groupName: String, iconId: Int, points: Double, timestamp: String, type: String, userId: String, username: String) {
        self.groupName = groupName
        self.iconId = iconId
        self.points = points
        self.timestamp = timestamp
        self.type = type
        self.userId = userId
        self.username = username
    }
}

enum EventType: String {
    case DRIVE_ADDED
    case DRIVE_DELETED
    case GROUP_CREATED
    case GROUP_JOINED
    case GROUP_LEFT
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
