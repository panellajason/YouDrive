//
//  SignInViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import FirebaseAuth
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkIfUserIsStillSignedIn()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Handles on-click for the sign-in button.
    @IBAction func signIn(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""

        guard let email = textfieldEmail.text else { return }
        guard let password = textfieldPassword.text else { return }
        guard !email.isEmpty && !password.isEmpty else {
            labelError.text = ValidationError.emptyTextFields.localizedDescription
            return
        }
        
        signUserIn(email: email, password: password)
    }
    
    // Uses UserDatabaseService to sign a user in.
    func signUserIn(email: String, password: String) {
        self.showSpinner(onView: self.view)
        UserDatabaseService.handleSignIn(email: email, password: password) {[weak self] error, currentUser in
            self?.removeSpinner()
            guard error == nil else {
                self?.labelError.text = ValidationError.invalidCredentials.localizedDescription
                return
            }
            guard currentUser.username != "" else { return }
            guard currentUser.homeGroup != "" else {
                self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
                return
            }
            
            self?.getAllGroupsForUser(userId: currentUser.userId)
            NavigationService.showMainNavController(shouldPassGroups: true)
        }
    }
    
    // Checks if user is still signed in and show main nav controller if they are in a group.
    private func checkIfUserIsStillSignedIn() {
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else { return }
        let userId = user.uid
        
        self.showSpinner(onView: self.view)
        UserDatabaseService.getUserDocument(userId: userId) { [weak self] error, currentUser in
            self?.removeSpinner()
            guard error == nil && currentUser.username != "" else { return }
            
            UserDatabaseService.currentUserProfile = currentUser
                        
            guard currentUser.homeGroup != "" else {
                self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
                return
            }
            
            self?.getAllGroupsForUser(userId: userId)
        }
    }
    
    // Gets all groups for current user.
    private func getAllGroupsForUser(userId: String) {
        GroupDatabaseService.getAllGroupsForUser(userId: userId) { [weak self] error, groupNames in
            guard error == nil else {
                self?.removeSpinner()
                return
            }
            
            UserDatabaseService.groupsForCurrentUser = groupNames
            NavigationService.showMainNavController(shouldPassGroups: true)
        }
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
