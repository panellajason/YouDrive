//
//  GroupDetailTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/6/22.
//

import UIKit

class DriveTableViewCell: UITableViewCell {

    static let identifier = "DriveTableViewCell"
    
    @IBOutlet weak var imageviewAvatar: UIImageView!
    @IBOutlet weak var labelDistance: UILabel!
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelPeopleInCar: UILabel!
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
        let imageName = WidgetService.ICON_PREFIX + drive.user.iconId.description
        imageviewAvatar.image =  UIImage(named: imageName)
        
        guard let timestamp = TimeInterval(drive.timestamp) else { return }
        let dateObj = Date(timeIntervalSince1970: timestamp)
        labelTimestamp.text = dateObj.timeAgoDisplay()
        
        labelDistance.text = drive.distance.description + " miles"
        labelLocation.text = drive.location
        labelPeopleInCar.text = "People in car: " + drive.peopleInCar.description
        labelPoints.text = drive.pointsEarned.description + " points"
        labelUserName.text = drive.user.username
    }
}
