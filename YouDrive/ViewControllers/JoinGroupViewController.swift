//
//  JoinGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import UIKit

class JoinGroupViewController: UIViewController {
    
    var shouldShowMainNavController: Bool = false
    
    @IBOutlet weak var buttonContinue: UIButton!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldGroupName: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter group name",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldGroupName.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldGroupPasscode: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter group passcode",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldGroupPasscode.attributedPlaceholder = placeholderText
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Handles on-click for continue button.
    @IBAction func handleContinueButton(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""

        guard textfieldGroupName.text != ""  && textfieldGroupPasscode.text != "" else {
            labelError.text = "Fields cannot be empty."
            return
        }
        
        joinGroup()
    }

    // Tries to join a group using DatabaseService.
    func joinGroup() {
        guard let groupName = textfieldGroupName.text else { return }
        guard let groupPasscode = textfieldGroupPasscode.text else { return }
        
        guard groupName != "" && groupPasscode != "" else {
            self.removeSpinner()
            labelError.text = "Fields cannot be empty."
            return
        }
        
        self.showSpinner(onView: self.view)
        
        GroupDatabaseService.joinGroup(
            groupName: groupName,
            groupPasscode: groupPasscode
        ){ [weak self] error, errorMessage, hasSuccessfullyJoined in
            
            guard error == nil else {
                self?.removeSpinner()
                self?.labelError.text = "Unable to join group: Server error."
                return
            }
            
            guard errorMessage == nil else {
                self?.removeSpinner()
                self?.labelError.text = errorMessage
                return
            }
            
            if hasSuccessfullyJoined {
                self?.removeSpinner()

                UserDatabaseService.currentUserProfile?.homeGroup = groupName
                    
                guard let showMainNavController = self?.shouldShowMainNavController else { return }
                
                if showMainNavController {
                    NavigationService.showMainNavController()
                } else {
                    
                    self?.dismiss(animated: true)
                    SideMenuTableViewController.selectedRow = 0
                    ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
                    HomeViewController.groupUpdatesDelegate?.onGroupUpdates()
                    NavigationService.mainNavController.popToRootViewController(animated: false)
                }
            } else {
                
                self?.removeSpinner()
                self?.labelError.text = "Group name and/or passcode incorrect."
            }
        }
    }
   
    // Hides keyboard when user taps screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
