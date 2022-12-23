//
//  NoGroupsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import UIKit

class NoGroupsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var buttonCreateGroup: UIButton!
    @IBOutlet weak var buttonJoinGroup: UIButton!
    @IBOutlet weak var imageViewIcon: UIImageView!
    @IBOutlet weak var labelUsername: UILabel!

    var alertController: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        imageViewIcon.image = UIImage(named: WidgetService.ICON_PREFIX + currentUser.iconId.description)
        labelUsername.text = currentUser.username
    }
    
    // Handles on-click for create group button.
    @IBAction func goToCreateGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateGroup.rawValue, sender: self)
    }
    
    // Handles on-click for join group button.
    @IBAction func goToJoinGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toJoinGroup.rawValue, sender: self)
    }
    
    // Handles on-click for sign out button.
    @IBAction func handleSignOut(_ sender: UIButton) {
        UserDatabaseService.handleSignOut()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueType.toCreateGroup.rawValue {
            let createGroupVc = segue.destination as! CreateGroupViewController
            createGroupVc.shouldShowMainNavController = true
        } else if segue.identifier == SegueType.toJoinGroup.rawValue {
            let joinGroupVc = segue.destination as! JoinGroupViewController
            joinGroupVc.shouldShowMainNavController = true
        }
    }
}
