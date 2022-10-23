//
//  JoinGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/22/22.
//

import UIKit

class JoinGroupViewController: UIViewController {

    @IBOutlet weak var buttonContinue: UIButton!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldGroupName: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter group passcode",
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
    
    // Handles on-click for continue button.
    @IBAction func handleContinueButton(_ sender: UIButton) {
        labelError.text = ""
        self.view.endEditing(true)

        guard textfieldGroupName.text != ""  && textfieldGroupPasscode.text != "" else {
            labelError.text = "Fields cannot be empty."
            return
        }
        
        joinGroup()
    }

    // Tries to join a group using DatabaseService.
    func joinGroup() {
        self.showSpinner(onView: self.view)

        guard textfieldGroupName?.text != "" && textfieldGroupPasscode?.text != "" else {
            self.removeSpinner()
            labelError.text = "Fields cannot be empty."
            return
        }
        
        DatabaseService.joinGroup(
            groupName: textfieldGroupName?.text ?? "",
            groupPasscode: textfieldGroupPasscode?.text ?? ""
        ){[weak self] error, errorMessage, hasSuccessfullyJoined in
            
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
                self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
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
