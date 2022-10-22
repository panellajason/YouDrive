//
//  SignInViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var buttonContinue: UIButton!
    @IBOutlet weak var labelError: UILabel!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Hide keyboard when user taps screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
    
    // Try to sign in user with DatabaseService on button click
    @IBAction func signIn(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""

        guard let email = textfieldEmail.text else { return }
        guard let password = textfieldPassword.text else { return }

        if !email.isEmpty && !password.isEmpty {
            self.showSpinner(onView: self.view)

            DatabaseService.handleSignIn(email: email, password: password) { [weak self] error in
                guard error == nil else {
                    self?.labelError.text = ValidationError.invalidCredentials.localizedDescription
                    self?.removeSpinner()
                    return
                }
                
                self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
            }
        } else {
            labelError.text = ValidationError.emptyTextFields.localizedDescription
        }
    }
}
