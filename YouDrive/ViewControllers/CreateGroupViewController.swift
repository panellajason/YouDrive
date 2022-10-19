//
//  CreateGroupViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/17/22.
//

import UIKit

class CreateGroupViewController: UIViewController {

    @IBOutlet weak var labelError: UILabel!
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
        labelError.text = ""

        guard textfieldGroupName.text != ""  && textfieldGroupPasscode.text != "" else {
            labelError.text = "Fields cannot be empty."
            return
        }
        
        self.showSpinner(onView: self.view)

        DatabaseService.createNewGroup(
            groupName: textfieldGroupName.text ?? "",
            groupPasscode: textfieldGroupPasscode.text ?? ""
        ){ [weak self] error, errorString in
            
            guard error == nil else {
                self?.removeSpinner()
                let errorAlert = UIAlertController(title: "Error", message: "Unable to create group.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self?.present(errorAlert, animated: true)
                return
            }
            
            guard errorString == nil else {
                self?.removeSpinner()
                self?.labelError.text = errorString
                return
            }
            
            self?.performSegue(withIdentifier: SegueType.toHome.rawValue, sender: self)
        }
    }
}
