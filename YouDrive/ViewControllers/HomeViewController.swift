//
//  HomeViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//
import BLTNBoard
import UIKit

class HomeViewController: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Sign out user and segue to entry view controller
    func signOutUser() {
        DatabaseService.handleSignOut()
        self.performSegue(withIdentifier: SegueType.toEntry.rawValue, sender: self)
    }

    // Handle on-click for the top nav bar account icon
    @IBAction func handleAccountAction(_ sender: Any) {
        accountDialog.showBulletin(above: self)
        
        DatabaseService.getGroupByName(groupName: "bois") { [weak self] error, group in
            
            guard error == nil else {
                return
            }
            
            print(group.groupName + group.groupPasscode)
        }
    }
}
