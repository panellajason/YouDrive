//
//  CreateGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import UIKit

class CreateGroupViewController: UIViewController {

    @IBOutlet weak var textfieldGroupName: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter group name",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldGroupName.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldGroupPasscode: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter group passcode",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldGroupPasscode.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var buttonCreateGroup: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func goToHome(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
    }
}
