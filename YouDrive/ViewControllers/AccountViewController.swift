//
//  AccountViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/23/22.
//

import BLTNBoard
import SideMenu
import UIKit

class AccountViewController: UIViewController, AccountUpdatesDelegate {

    private var sideMenu: SideMenuNavigationController?

    static var accountUpdatesDelegate: AccountUpdatesDelegate?

    @IBOutlet weak var imageviewUserIcon: UIImageView!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelUsername: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Your account"
        
        AccountViewController.accountUpdatesDelegate = self
        setupSideMenu()
        setupUI()
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    @IBAction func handleSignOutButton(_ sender: Any) {
        showSignOutConfirmation()
    }
    
    // Sets up navigation side menu.
    private func setupSideMenu() {
        sideMenu = SideMenuNavigationController(rootViewController: SideMenuTableViewController())
        sideMenu?.leftSide = true
        sideMenu?.setNavigationBarHidden(true, animated: true)
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    private func setupUI() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        let imageName = WidgetService.ICON_PREFIX + currentUser.iconId.description
        imageviewUserIcon.image =  UIImage(named: imageName)
        
        labelEmail.text = currentUser.email
        labelUsername.text = currentUser.username
    }
    
    // Shows confirmation dialog before leaving group.
    private func showSignOutConfirmation() {
        let alertController = UIAlertController(title: "Are you sure you want to sign out?", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Sign out", style: UIAlertAction.Style.default) { UIAlertAction in
            UserDatabaseService.handleSignOut()
        }
        okAction.setValue(UIColor.red, forKey: "titleTextColor")
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            print("Cancel Pressed")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    func onAccountUpdated() {
        setupUI()
    }
}
