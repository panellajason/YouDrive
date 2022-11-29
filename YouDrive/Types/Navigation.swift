//
//  Segue.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import Foundation

// Segue names.
enum SegueType: String {
    case toAddDrive
    case toCreateGroup
    case toGroupDetail
    case toJoinGroup
    case toNoGroups
    case toSearchResults
}

// Side bar menu items.
enum SideBarNavItem: String {
    case Home = "Home"
    case ActivityFeed = "Activity feed"
    case ManageGroups = "Manage groups"
    case SignOut = "Sign out"
}

// Manage group options.
enum ManageGroupOptions: String {
    case CreateGroup = "Create a group"
    case JoinGroup = "Join a group"
}
