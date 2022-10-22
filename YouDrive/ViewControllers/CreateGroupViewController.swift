//
//  CreateGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import UIKit

class CreateGroupViewController: UIViewController {

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
    
    // Handles on-click for continue button
    @IBAction func handleCreateGroupButton(_ sender: UIButton) {
        labelError.text = ""
        self.view.endEditing(true)

        guard textfieldGroupName.text != ""  && textfieldGroupPasscode.text != "" && textfieldConfirmPasscode.text != "" else {
            labelError.text = "Fields cannot be empty."
            return
        }
        
        guard textfieldGroupPasscode.text == textfieldConfirmPasscode.text else {
            labelError.text = "Passcodes must match."
            return
        }
        
        createNewGroup()
    }
    
    // Uses DatabaseService to create new group in Firestore
    private func createNewGroup() {
        self.showSpinner(onView: self.view)

        DatabaseService.createNewGroup(
            groupName: textfieldGroupName.text ?? "",
            groupPasscode: textfieldGroupPasscode.text ?? ""
        ){ [weak self] error, errorString in
            
            guard error == nil else {
                self?.removeSpinner()
                let errorAlert = UIAlertController(title: "Error", message: "Unable to create group.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                self?.present(errorAlert, animated: true)
                return
            }
            
            guard errorString == nil else {
                self?.removeSpinner()
                self?.labelError.text = errorString
                return
            }
            
            self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
        }
    }
    
    // Hides keyboard when user taps screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
