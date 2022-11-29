//
//  ActivityFeedTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/4/22.
//

import UIKit

class ActivityFeedTableViewCell: UITableViewCell {
    static let identifier = "ActivityFeedTableViewCell"
    
    @IBOutlet weak var imageViewIcon: UIImageView!
    @IBOutlet weak var labelEvent: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with event: Event) {
        
        imageViewIcon.image = UIImage(named: WidgetService.ICON_PREFIX + event.iconId.description)

        guard let timestamp = TimeInterval(event.timestamp) else { return }
        let dateObj = Date(timeIntervalSince1970: timestamp)
        labelTimestamp.text = dateObj.timeAgoDisplay()
        
        switch(event.type) {
            
        case EventType.DRIVE_ADDED.rawValue:
            labelEvent.text = event.username + " received " + event.points.rounded(toPlaces: 1).description + " points in group: " + event.groupName
            break
            
        case EventType.DRIVE_DELETED.rawValue:
            labelEvent.text = event.username + "'s drive for " + event.points.rounded(toPlaces: 1).description + " points in group: " + event.groupName + " was deleted"
            break
            
        case EventType.GROUP_CREATED.rawValue:
            labelEvent.text = event.username + " created a new group: " + event.groupName
            break
            
        case EventType.GROUP_JOINED.rawValue:
            labelEvent.text = event.username + " joined the group: " + event.groupName
            break
            
        case EventType.GROUP_LEFT.rawValue:
            labelEvent.text = event.username + " left the group: " + event.groupName
            break
            
        default:
            break
        }
    }
}
