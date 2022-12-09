//
//  GroupDetailViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/6/22.
//

import DropDown
import UIKit

class GroupDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let moreOptionsDropdown: DropDown = DropDown()

    private var drivesList: [Drive] = []
    
    var passedGroupName: String?

    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var tableViewDrives: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let groupName = self.passedGroupName else {
            self.dismiss(animated: true)
            return
        }
        
        labelTitle.text = groupName
        getAllDrivesForGroup(groupName: groupName)
        
        setupDropdown()
        setupTableView()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func deleteDrive(index: Int) {
        self.showSpinner(onView: self.view)
        
        DriveDatabaseService.deleteDriveDocument(driveToDelete: drivesList[index]) { error in
            self.removeSpinner()
            guard error == nil else { return }
        }
        
        drivesList.remove(at: index)
        tableViewDrives.reloadData()
        
        if drivesList.count == 0 {
            tableViewDrives.backgroundColor = .clear
        }
    }
    
    // Handles on-click for the more options button.
    @IBAction func handleMoreOptionsButton(_ sender: Any) {
        moreOptionsDropdown.show()
        moreOptionsDropdown.clearSelection()
    }
    
    // Gets all drives for a group.
    private func getAllDrivesForGroup(groupName: String) {
        self.showSpinner(onView: self.tableViewDrives)
                
        DriveDatabaseService.getAllDrivesForGroupName(groupName: groupName) { [weak self] error, drives in
            self?.removeSpinner()
            guard error == nil else { return }
            
            if drives.count == 0 {
                self?.tableViewDrives.backgroundColor = .clear
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
            guard error == nil else { return }
            self?.dismiss(animated: true)
        }
    }
    
    // Shows confirmation dialog before leaving group.
    private func showDeleteDriveConfirmation(index: Int) {
        let alertController = UIAlertController(title: "Are you sure you want to delete this drive?", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.default) { [weak self] UIAlertAction in
            self?.deleteDrive(index: index)
        }
        okAction.setValue(UIColor.red, forKey: "titleTextColor")
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            print("Cancel Pressed")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    // Shows confirmation dialog before leaving group.
    private func showLeaveGroupConfirmation() {
        let alertController = UIAlertController(title: "Are you sure you want to leave this group?", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Leave", style: UIAlertAction.Style.default) { [weak self] UIAlertAction in
            self?.leaveGroup()
        }
        okAction.setValue(UIColor.red, forKey: "titleTextColor")
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
    }
    
    private func setupDropdown() {
        moreOptionsDropdown.anchorView = moreButton
        moreOptionsDropdown.bottomOffset = CGPoint(x: CGFloat(-80), y: CGFloat(30))
        moreOptionsDropdown.textColor = .red
        moreOptionsDropdown.selectedTextColor = .red
        moreOptionsDropdown.backgroundColor = .white
        moreOptionsDropdown.dataSource = [ManageGroupOptions.LeaveGroup.rawValue]
        moreOptionsDropdown.selectionAction = { [weak self] index, title in
            self?.showLeaveGroupConfirmation()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drivesList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: DriveTableViewCell.identifier,
                                                        for: indexPath) as! DriveTableViewCell
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
            showDeleteDriveConfirmation(index: indexPath.row)
        }
    }
}
