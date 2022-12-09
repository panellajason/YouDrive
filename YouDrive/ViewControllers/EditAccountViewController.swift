//
//  EditAccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 12/2/22.
//

import UIKit

class EditAccountViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var iconIdList = WidgetService.getIconIdList()
    var selectedIcon = 0
    
    @IBOutlet weak var collectionViewIcons: UICollectionView!
    @IBOutlet weak var labelError: UILabel!
    @IBOutlet weak var textfieldUsername: UITextField! {
        didSet {
            let placeholderText = NSAttributedString(string: "Display name",
                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            guard let currentUser = UserDatabaseService.currentUserProfile else {
                self.dismiss(animated: true)
                return
            }
            textfieldUsername.text = currentUser.username
            textfieldUsername.attributedPlaceholder = placeholderText
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectUserIcon()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleSaveAction(_ sender: Any) {
        self.view.endEditing(true)
        labelError.text = ""
                
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        guard let preTrimmedUsername = textfieldUsername.text else { return }
        let username = preTrimmedUsername.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        
        guard !username.isEmpty else {
            labelError.text = "Display name cannot be empty."
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

        guard currentUser.username != username || currentUser.iconId != selectedIcon else {
            self.dismiss(animated: true)
            return
        }
        
        currentUser.username = username
        currentUser.iconId = selectedIcon
        save(accountToUpdate: currentUser)
    }
    
    private func save(accountToUpdate: User) {
        UserDatabaseService.editUser(accountToUpdate: accountToUpdate) { [weak self] error in
            guard error == nil else { return }
            self?.dismiss(animated: true)
        }
    }
    
    private func selectUserIcon() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        guard  let userIcon = iconIdList.firstIndex(of: currentUser.iconId) else { return }
        iconIdList.swapAt(0, userIcon)
        
        guard let iconId = iconIdList.first else { return }
        selectedIcon = iconId
        
        let indexPath = IndexPath(row: 0, section: 0)
        collectionViewIcons.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
    }
    
    private func setupCollectionView() {
        collectionViewIcons.dataSource = self
        collectionViewIcons.delegate = self
        collectionViewIcons.collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewIcons.allowsMultipleSelection = false
        if let layout = collectionViewIcons.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
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
