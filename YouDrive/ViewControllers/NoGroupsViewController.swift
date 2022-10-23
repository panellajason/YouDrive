//
//  NoGroupsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import BLTNBoard
import UIKit

class NoGroupsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var buttonCreateGroup: UIButton!
    @IBOutlet weak var buttonJoinGroup: UIButton!
    
    var alertController: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Handles on-click for create group button.
    @IBAction func goToCreateGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateGroup.rawValue, sender: self)
    }
    
    // Handles on-click for join group button.
    @IBAction func goToJoinGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toJoinGroup.rawValue, sender: self)
    }
}
