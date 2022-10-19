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
    
    // Handles on-click for create group button
    @IBAction func goToCreateGroup(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateGroup.rawValue, sender: self)
    }
    
    // Handles on-click for join group button
    @IBAction func openJoinGroupDialog(_ sender: UIButton) {
        setUpJoinGroupAlertController()
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Uses DatabaseService to join group
    func joinGroup() {
        self.showSpinner(onView: self.view)

        let errorAlert = UIAlertController(title: "Unable to join group", message: "", preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        
        let textfieldGroupName = (self.alertController.textFields?[0]) as UITextField?
        let textfieldGroupCode = (self.alertController.textFields?[1]) as UITextField?

        guard textfieldGroupCode?.text != "" else {
            self.removeSpinner()
            errorAlert.message = "Fields cannot be empty."
            self.present(errorAlert, animated: true)
            return
        }
        
        DatabaseService.joinGroup(
            groupName: textfieldGroupName?.text ?? "",
            groupPasscode: textfieldGroupCode?.text ?? ""
        ){[weak self] error, errorMessage, hasSuccessfullyJoined in
            
            guard error == nil else {
                self?.removeSpinner()
                errorAlert.message = "Server error."
                self?.present(errorAlert, animated: true)
                return
            }
            
            guard errorMessage == nil else {
                self?.removeSpinner()
                errorAlert.message = errorMessage
                self?.present(errorAlert, animated: true)
                return
            }
            
            if hasSuccessfullyJoined {
                self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
            } else {
                self?.removeSpinner()
                errorAlert.message = "Group name and/or passcode incorrect."
                self?.present(errorAlert, animated: true)
            }
        }
    }
    
    // Alert controller for joining a group
    func setUpJoinGroupAlertController() {
        alertController = UIAlertController(title: "Join a group", message: "", preferredStyle: .alert)

        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter group name"
        }
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter group passcode"
        }
                
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelButtonAction)
        
        let continueButtonAction = UIAlertAction(title: "Continue", style: .default, handler: {[weak self] alert -> Void in
            self?.joinGroup()
        })
        alertController.addAction(continueButtonAction)
    }
}
