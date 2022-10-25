//
//  AccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/23/22.
//

import BLTNBoard
import UIKit

class AccountViewController: UIViewController {

    // Account dialog which has button to sign user out.
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
    
    // Handles on-click for the top nav bar account icon.
    @IBAction func handleAccountAction(_ sender: Any) {
        accountDialog.showBulletin(above: self)
    }
    
    // Signs out user and segue to entry view controller.
    func signOutUser() {
        UserDatabaseService.handleSignOut()
        self.performSegue(withIdentifier: SegueType.toEntry.rawValue, sender: self)
    }
}
