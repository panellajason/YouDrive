//
//  CreateAccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var buttonContinute: UIButton!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldConfirmPassword: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Confirm password",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldConfirmPassword.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldEmail: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Email address",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldEmail.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldPassword: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Password",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldPassword.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldUsername: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Display name",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldUsername.attributedPlaceholder = placeholderText
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Tries to create a user account with DatabaseService.
    @IBAction func createAccount(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""
        
        guard let email = textfieldEmail.text else { return }
        guard let password1 = textfieldPassword.text else { return }
        guard let password2 = textfieldConfirmPassword.text else { return }
        guard let username = textfieldUsername.text else { return }

        if !email.isEmpty && !password1.isEmpty && !password2.isEmpty {
            
            if password1 == password2 {
                
                self.showSpinner(onView: self.view)

                let accountToCreate = User(email: email, homeGroup: "", userId: "", username: username)
                
                UserDatabaseService.createUserAccount(accountToCreate: accountToCreate, password: password1) { [weak self] error in
                    
                    guard error == nil else {
                        self?.labelError.text = error?.localizedDescription
                        self?.removeSpinner()
                        return
                    }
                    
                    self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
                }
            } else {
                
                labelError.text = ValidationError.passwordsMustMatch.localizedDescription
            }
        } else {
            
            labelError.text = ValidationError.emptyTextFields.localizedDescription
        }
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
