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
        setUpJoinGroupAlertController()
    }
    
    // Alert controller for joining a group
    func setUpJoinGroupAlertController() {
        alertController = UIAlertController(title: "Join a group", message: "", preferredStyle: .alert)

        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter group passcode"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Continue", style: .default, handler: { alert -> Void in
            let textfieldGroupCode = self.alertController.textFields![0] as UITextField
            
            print(textfieldGroupCode.text?.description ?? "")
            
            // if there exists a group with this passcode, then add this user to the group
            
            self.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
        })
        alertController.addAction(saveAction)
    }
    
    // Handle on-click for create group button
    @IBAction func goToCreateGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateGroup.rawValue, sender: self)
    }
    
    // Handle on-click for join group button
    @IBAction func openJoinGroupDialog(_ sender: UIButton) {
        self.present(alertController, animated: true, completion: nil)
    }
    
}
