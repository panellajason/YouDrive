//
//  ViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit
import FirebaseAuth

class EntryViewController: UIViewController {

    @IBOutlet weak var buttonSignIn: UIButton!
    @IBOutlet weak var buttonCreateAccount: UIButton!
    
    // Checks if user is still signed in and will segue to home if they are in a group
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let currentUser = Auth.auth().currentUser
        guard currentUser != nil else { return }
        guard let userId = currentUser?.uid else { return  }

        self.showSpinner(onView: self.view)

        UserDatabaseService.getUserDocument(userId: userId) {[weak self] error, currentUser in
            
            guard error == nil else {
                self?.removeSpinner()
                return
            }
            
            UserDatabaseService.currentUserProfile = currentUser
                        
            guard currentUser.homeGroup != "" else {
                self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
                return
            }
            
            GroupDatabaseService.getAllGroupsForUser(userId: userId) {[weak self] error, groupNames in
                
                guard error == nil else {
                    self?.removeSpinner()
                    return
                }
                
                self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Handles on-click for create account button.
    @IBAction func goToCreateAccount(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateAccount.rawValue, sender: self)
    }
    
    // Handles on-click for sign in button.
    @IBAction func goToSignIn(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toSignIn.rawValue, sender: self)
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

