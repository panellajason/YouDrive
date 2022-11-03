//
//  ManageGroupsTableViewCell.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/5/22.
//

import UIKit

class ManageGroupsTableViewCell: UITableViewCell {

    static let identifier = "ManageGroupsTableViewCell"
    
    @IBOutlet weak var buttonLeaveGroup: UIButton!
    @IBOutlet weak var labelGroupName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with groupName: String) {
        labelGroupName.text = groupName
    }
}
