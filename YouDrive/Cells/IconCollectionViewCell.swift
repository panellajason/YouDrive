//
//  IconCollectionViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/2/22.
//

import UIKit

class IconCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "IconCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    
    func configure(iconId: String) {
        let iconImageId = WidgetService.ICON_PREFIX + iconId
        imageView.image = UIImage(named: iconImageId)
    }
}
