//
//  SignInViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var textfieldEmail: UITextField!
    @IBOutlet weak var textfieldPassword: UITextField!
    @IBOutlet weak var buttonContinue: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func login(_ sender: UIButton) {
            guard let email = textfieldEmail.text else { return }
            guard let password = textfieldPassword.text else { return }

            self.view.endEditing(true)

            if !email.isEmpty && !password.isEmpty {

                DatabaseService.handleSignIn(email: email, password: password) { [weak self] error in
                    
                    guard error == nil else {
                        return
                    }
                    
                    self?.performSegue(withIdentifier: "toHome", sender: self)
                }
            } else {

            }
        }
    
}
