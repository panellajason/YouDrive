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
    
    // Checks if user is still signed in and will segue to home if they are.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if DatabaseService.getCurrentUser() != nil {
            self.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
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
}

