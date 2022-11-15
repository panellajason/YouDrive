//
//  GroupDetailViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/6/22.
//

import UIKit

class GroupDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var drivesList: [Drive] = []
    
    var passedGroupName: String?

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var tableViewDrives: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            
        guard let groupName = self.passedGroupName else {
            self.dismiss(animated: true)
            return
        }
        
        labelTitle.text = groupName
        getAllDrivesForGroup(groupName: groupName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Handles on-click for the leave group button.
    @IBAction func handleLeaveGroupButton(_ sender: Any) {
        showLeaveGroupConfirmation()
    }
    
    // Gets all drives for a group.
    func getAllDrivesForGroup(groupName: String) {
        self.showSpinner(onView: self.tableViewDrives)
                
        DriveDatabaseService.getAllDrivesForGroupName(groupName: groupName) { [weak self] error, drives in
            self?.removeSpinner()
            
            guard error == nil && drives.count != 0 else {
                return
            }
            
            self?.drivesList = drives
            self?.tableViewDrives.reloadData()
        }
    }
    
    // Removes user from group.
    private func leaveGroup() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        guard let groupName = self.passedGroupName else { return }
        self.showSpinner(onView: self.view)
                    
        GroupDatabaseService.deleteUserGroupsDocument(groupName: groupName, userId: currentUser.userId) { [weak self] error in
            self?.removeSpinner()

            guard error == nil else {
                return
            }
            self?.dismiss(animated: true)
        }
    }
    
    // Shows confirmation dialog before leaving group.
    private func showLeaveGroupConfirmation() {
        let alertController = UIAlertController(title: "Are you sure you want to leave this group?", message: "", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Leave", style: UIAlertAction.Style.default) { [weak self] UIAlertAction in
            self?.leaveGroup()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            print("Cancel Pressed")
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    private func setupTableView() {
        tableViewDrives.dataSource = self
        tableViewDrives.delegate = self
        tableViewDrives.backgroundColor = .white
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drivesList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: GroupDetailTableViewCell.identifier,
                                                        for: indexPath) as! GroupDetailTableViewCell
        resultsCell.configure(with: drivesList[indexPath.row])
        return resultsCell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete drive"
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            print("deleted")
        }
    }
}
