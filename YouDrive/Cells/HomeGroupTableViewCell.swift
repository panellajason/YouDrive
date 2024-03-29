//
//  HomeGroupTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/23/22.
//

import UIKit

// Tableview cell for displaying users in a selected group on the home tab.
class HomeGroupTableViewCell: UITableViewCell {

    static let identifier = "HomeGroupTableViewCell"
    
    @IBOutlet weak var imageviewAvatar: UIImageView!
    @IBOutlet weak var labelPointsInGroup: UILabel!
    @IBOutlet weak var labelUserName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with userGroup: UserGroup) {
        let imageName = WidgetService.ICON_PREFIX + userGroup.iconId.description

        imageviewAvatar.image =  UIImage(named: imageName)
        labelPointsInGroup.text = userGroup.pointsInGroup.description + " points"
        labelUserName.text = userGroup.username
    }
}
