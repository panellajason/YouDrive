//
//  CreateAccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import UIKit

class CreateAccountViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var iconIdList = WidgetService.getIconIdList()
    var selectedIcon = 0
    
    @IBOutlet weak var collectionViewIcons: UICollectionView!
    @IBOutlet weak var buttonContinute: UIButton!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldConfirmPassword: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Confirm password",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldConfirmPassword.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldEmail: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter email address",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldEmail.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldPassword: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter password",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldPassword.attributedPlaceholder = placeholderText
        }
    }
    @IBOutlet weak var textfieldUsername: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Enter display name",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            textfieldUsername.attributedPlaceholder = placeholderText
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let indexPath = IndexPath(row: 0, section: 0)
        collectionViewIcons.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
        
        guard let iconId = iconIdList.first else { return }
        selectedIcon = iconId
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewIcons.dataSource = self
        collectionViewIcons.delegate = self
        collectionViewIcons.collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewIcons.allowsMultipleSelection = false
        if let layout = collectionViewIcons.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
    }
    
    // Handles on-click for create account button.
    @IBAction func createAccount(_ sender: UIButton) {
        self.view.endEditing(true)
        labelError.text = ""
        
        guard let email = textfieldEmail.text else { return }
        guard let password1 = textfieldPassword.text else { return }
        guard let password2 = textfieldConfirmPassword.text else { return }
        guard let preTrimmedUsername = textfieldUsername.text else { return }
        let username = preTrimmedUsername.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        
        guard !email.isEmpty && !password1.isEmpty && !password2.isEmpty && !username.isEmpty else {
            labelError.text = ValidationError.emptyTextFields.localizedDescription
            return
        }
        
        guard password1 == password2 else {
            labelError.text = ValidationError.passwordsMustMatch.localizedDescription
            return
        }
        
        guard username.count <= 25 else {
            labelError.text = "Display name must be less than 25 characters."
            return
        }
        
        guard selectedIcon != 0 else {
            labelError.text = "Please select an icon."
            return
        }

        let accountToCreate = User(email: email, homeGroup: "", iconId: selectedIcon, userId: "", username: username)
        createAccount(accountToCreate: accountToCreate, password: password1)
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Uses UserDatabaseService to create a user account.
    func createAccount(accountToCreate: User, password: String) {
        self.showSpinner(onView: self.view)
        UserDatabaseService.createUserAccount(accountToCreate: accountToCreate, password: password) { [weak self] error in
            self?.removeSpinner()
            guard error == nil else {
                self?.labelError.text = error?.localizedDescription
                return
            }
            self?.performSegue(withIdentifier: SegueType.toNoGroups.rawValue, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 75, height: 75)
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iconIdList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconCollectionViewCell.identifier, for: indexPath) as! IconCollectionViewCell
        let iconId: Int = iconIdList[indexPath.row]
        cell.configure(iconId: iconId)
        
        let selectedColor = UIView()
        selectedColor.backgroundColor = UIColor.systemBlue
        cell.selectedBackgroundView = selectedColor
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIcon = iconIdList[indexPath.row]
    }
    
    // Hides keyboard when user taps screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.view.endEditing(true)
    }
}
