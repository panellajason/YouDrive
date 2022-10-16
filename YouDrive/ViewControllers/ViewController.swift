//
//  ViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var buttonSignIn: UIButton!
    @IBOutlet weak var buttonCreateAccount: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goToCreateAccount(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toCreateAccount", sender: self)
    }
    
    @IBAction func goToSignIn(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toSignIn", sender: self)
    }
}

