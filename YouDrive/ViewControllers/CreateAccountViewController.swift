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

    @IBAction func goToHome(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toHome", sender: self)
    }
}
