//
//  HomeViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//
import BLTNBoard
import DropDown
import UIKit

class HomeViewController: UIViewController {
    
    var groupsNamesForUser: [String]?
    
    // Account dialog which has button to sign user out
    private lazy var accountDialog: BLTNItemManager = {
        let item = BLTNPageItem(title: "Account")
        item.appearance.titleTextColor = .systemBlue
        item.actionButtonTitle = "Sign out"
        item.appearance.actionButtonColor = .systemRed
        item.actionHandler = { [weak self] _ in
            guard let self = self else { return }
            self.signOutUser()
        }
        return BLTNItemManager(rootItem: item)
    }()
    // Dropdown to select a group that the user is in
    private let groupsDropdown: DropDown = DropDown()
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DatabaseService.getAllGroupsForUser() {error, names in
            
            guard error == nil else {
                return
            }
            
            print(names)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupsDropdown.dataSource = groupsNamesForUser ?? []
    }
    
    // Sign out user and segue to entry view controller
    func signOutUser() {
        DatabaseService.handleSignOut()
        self.performSegue(withIdentifier: SegueType.toEntry.rawValue, sender: self)
    }

    // Handle on-click for the top nav bar account icon
    @IBAction func handleAccountAction(_ sender: Any) {
        accountDialog.showBulletin(above: self)
    }
}
