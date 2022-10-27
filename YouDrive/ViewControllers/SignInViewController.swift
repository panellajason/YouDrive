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
    
    // Tries to sign a user in with DatabaseService.
    @IBAction func signIn(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""

        guard let email = textfieldEmail.text else { return }
        guard let password = textfieldPassword.text else { return }

        if !email.isEmpty && !password.isEmpty {
            
            self.showSpinner(onView: self.view)

            UserDatabaseService.handleSignIn(email: email, password: password) {[weak self] error, currentUser in
                
                guard error == nil else {
                    self?.labelError.text = ValidationError.invalidCredentials.localizedDescription
                    self?.removeSpinner()
                    return
                }
                
                guard currentUser.homeGroup != "" else {
                    self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
                    return
                }
                
                GroupDatabaseService.getAllGroupsForUser(userId: UserDatabaseService.currentUserProfile?.userId ?? "") {[weak self]
                    error, groupNames in
                    
                    guard error == nil else {
                        self?.removeSpinner()
                        return
                    }
                    
                    self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
                }
            }
        } else {
            
            labelError.text = ValidationError.emptyTextFields.localizedDescription
        }
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
    
    // Sets up HomeViewController before segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueType.toHome.rawValue {
            let tabBarController = segue.destination as! UITabBarController
            let navController = tabBarController.viewControllers![0] as! UINavigationController
            let homeViewController = navController.viewControllers.first as! HomeViewController
            homeViewController.passedGroupsForUser = UserDatabaseService.groupsForCurrentUser
        }
    }
}
