//
//  CreateAccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var buttonContinute: UIButton!
    @IBOutlet weak var textfieldEmail: UITextField!
    @IBOutlet weak var textfieldPassword: UITextField!
    @IBOutlet weak var textfieldConfirmPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func signUp(_ sender: UIButton) {
            guard let email = textfieldEmail.text else { return }
            guard let password1 = textfieldPassword.text else { return }
            guard let password2 = textfieldConfirmPassword.text else { return }

            self.view.endEditing(true)

            if !email.isEmpty && !password1.isEmpty && !password2.isEmpty {
                if password1 == password2 {
                    DatabaseService.handleSignUp(email: email, password: password1) { [weak self] error in
                        
                        guard error == nil else {
                            return
                        }
                        
                        self?.performSegue(withIdentifier: "toHome", sender: self)
                    }
                } else {
                    //errorLabel.text = ValidationError.passwordsMustMatch.localizedDescription
                }
            } else {
                //errorLabel.text = ValidationError.emptyTextFields.localizedDescription
            }
        }

    @IBAction func goToHome(_ sender: UIButton) {
    }
}
