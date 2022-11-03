//
//  ManageGroupsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/2/22.
//

import SideMenu
import UIKit

class ManageGroupsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupUpdatesDelegate {

    private var groupsList: [String] = []
    private var sideMenu: SideMenuNavigationController?

    @IBOutlet weak var tableViewManageGroups: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupsList = UserDatabaseService.groupsForCurrentUser
        setupTableView()
        setupSideMenu()
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    private func leaveGroup(indexToDelete: Int) {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        self.showSpinner(onView: self.view)
                    
        GroupDatabaseService.deleteUserGroupsDocument(groupName: groupsList[indexToDelete], userId: currentUser.userId) { [weak self] error in
            
            guard error == nil else {
                return
            }
            
            print("h")
            self?.tableViewManageGroups.reloadData()
            self?.removeSpinner()
        }
        
        groupsList.remove(at: indexToDelete)
    }
    
    // Reload data when a user's groups are updated.
    func onGroupUpdates() {
        groupsList = UserDatabaseService.groupsForCurrentUser
    }
    
    // Sets up navigation side menu.
    private func setupSideMenu() {
        sideMenu = SideMenuNavigationController(rootViewController: SideMenuTableViewController())
        sideMenu?.leftSide = true
        sideMenu?.setNavigationBarHidden(true, animated: true)
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        //SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    private func setupTableView() {
        tableViewManageGroups.dataSource = self
        tableViewManageGroups.delegate = self
        tableViewManageGroups.backgroundColor = .white
    }
    
    private func showLeaveGroupConfirmation(indexToDelete: Int) {
        let alertController = UIAlertController(title: "Are you sure you want to leave this group?", message: "", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Leave", style: UIAlertAction.Style.default) { [weak self] UIAlertAction in
            self?.leaveGroup(indexToDelete: indexToDelete)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            print("Cancel Pressed")
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: SegueType.toGroupDetail.rawValue, sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: ManageGroupsTableViewCell.identifier,
                                                        for: indexPath) as! ManageGroupsTableViewCell
        resultsCell.configure(with: groupsList[indexPath.row])
        return resultsCell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Leave group"
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            showLeaveGroupConfirmation(indexToDelete: indexPath.row)
        }
    }
}
