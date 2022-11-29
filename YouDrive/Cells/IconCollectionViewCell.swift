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
    
    func configure(iconId: Int) {
        let iconImageId = WidgetService.ICON_PREFIX + iconId.description
        imageView.image = UIImage(named: iconImageId)
    }
}
