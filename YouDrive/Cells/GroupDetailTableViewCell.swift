//
//  GroupDetailTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/6/22.
//

import UIKit

class GroupDetailTableViewCell: UITableViewCell {

    static let identifier = "GroupDetailTableViewCell"
    
    @IBOutlet weak var imageviewAvatar: UIImageView!
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelPoints: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!
    @IBOutlet weak var labelUserName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with drive: Drive) {
        let imageName = "icon_" + drive.user.iconId.description
        imageviewAvatar.image =  UIImage(named: imageName)
        
        guard let timestamp = TimeInterval(drive.timestamp) else { return }
        let dateObj = Date(timeIntervalSince1970: timestamp)
        labelTimestamp.text = dateObj.timeAgoDisplay()
        
        labelLocation.text = drive.location
        labelPoints.text = drive.pointsEarned.description + " points"
        labelUserName.text = drive.user.username
    }
}
