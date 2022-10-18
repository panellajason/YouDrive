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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if DatabaseService.getCurrentUser() != nil {
            self.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goToCreateAccount(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toCreateAccount.rawValue, sender: self)
    }
    
    @IBAction func goToSignIn(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toSignIn.rawValue, sender: self)
    }
}

