//
//  CreateGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import UIKit

class CreateGroupViewController: UIViewController {
    
    static var groupUpdatesDelegate: GroupUpdatesDelegate?
    var shouldShowMainNavController: Bool = false

    @IBOutlet weak var buttonCreateGroup: UIButton!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldConfirmPasscode: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Confirm passcode",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldConfirmPasscode.attributedPlaceholder = placeholderText
        }
    }
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
    
    // Handles on-click for create group (continue) button.
    @IBAction func handleCreateGroupButton(_ sender: UIButton) {
        labelError.text = ""
        self.view.endEditing(true)
    
        guard let preTrimmedGroupName = textfieldGroupName.text else { return }
        guard let groupPasscode = textfieldGroupPasscode.text else { return }
        guard let confirmedPasscode = textfieldConfirmPasscode.text else { return }
        let groupName = preTrimmedGroupName.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                
        guard !groupName.isEmpty  && !groupPasscode.isEmpty && !confirmedPasscode.isEmpty else {
            labelError.text = "Fields cannot be empty."
            return
        }
        
        guard groupName.count <= 25 else {
            labelError.text = "Group name must be less than 25 characters."
            return
        }
        
        guard textfieldGroupPasscode.text == textfieldConfirmPasscode.text else {
            labelError.text = "Passcodes must match."
            return
        }
        
        createNewGroup(groupName: groupName, groupPasscode: groupPasscode)
    }
    
    // Uses DatabaseService to create new group.
    private func createNewGroup(groupName: String, groupPasscode: String) {
        self.showSpinner(onView: self.view)

        GroupDatabaseService.createNewGroup(
            groupName: groupName,
            groupPasscode: groupPasscode
        ){ [weak self] error, errorString in
            
            self?.removeSpinner()

            guard error == nil else {
                self?.labelError.text = "Unable to create group, please try again."
                return
            }
            
            guard errorString == nil else {
                self?.labelError.text = errorString
                return
            }
            
            
            guard let showMainNavController = self?.shouldShowMainNavController else { return }
            if showMainNavController {
                NavigationService.showMainNavController(shouldPassGroups: false)
            } else {
                self?.dismiss(animated: true)
                SideMenuTableViewController.selectedRow = 0
                ActivityFeedViewController.eventUpdatesDelegate?.onEventUpdates()
                HomeViewController.groupUpdatesDelegate?.onGroupUpdates()
                NavigationService.mainNavController.popToRootViewController(animated: false)
            }
        }
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
