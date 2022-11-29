//
//  SideMenuTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/16/22.
//

import UIKit

class SideMenuTableViewCell: UITableViewCell {

    static let identifier = "SideMenuTableViewCell"

    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with navLabel: String) {
        label.text = navLabel
        
        switch navLabel {
        case SideBarNavItem.Home.rawValue:
            imageview.image = UIImage(systemName: "house", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
            break
        case SideBarNavItem.ActivityFeed.rawValue:
            imageview.image = UIImage(systemName: "text.bubble.rtl", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
            break
        case SideBarNavItem.ManageGroups.rawValue:
            imageview.image = UIImage(systemName: "person.2", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
            break
        case SideBarNavItem.SignOut.rawValue:
            imageview.image = UIImage(systemName: "iphone.and.arrow.forward", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
            break
        default:
            break
        }
    }
}
