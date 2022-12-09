//
//  UserDetailViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/30/22.
//

import UIKit

class UserDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var userDrivesList: [Drive] = []

    var passedUser: UserGroup?

    @IBOutlet weak var imageviewUserIcon: UIImageView!
    @IBOutlet weak var labelLongestDrive: UILabel!
    @IBOutlet weak var labelNoDrivesInThisGroup: UILabel!
    @IBOutlet weak var labelPoints: UILabel!
    @IBOutlet weak var labelSeparator: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelTotalDrives: UILabel!
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var tableviewUserDrives: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = passedUser else {
            self.dismiss(animated: true)
            return
        }
        
        getAllDrivesForGroup(user: user)
        setupUI(user: user)
        setupTableView()
    }
    
    // Handles on-click for the "X" button.
    @IBAction func handleCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Gets all drives for a user in a group.
    private func getAllDrivesForGroup(user: UserGroup) {
        self.showSpinner(onView: self.tableviewUserDrives)
        DriveDatabaseService.getAllDrivesForUserInGroup(groupName: user.groupName, userId: user.userId) { [weak self] error, drives in
            self?.removeSpinner()
            guard error == nil else { return }
            
            if drives.count == 0 {
                self?.tableviewUserDrives.backgroundColor = .clear
                self?.labelLongestDrive.text = ""
                self?.labelPoints.text = ""
                self?.labelTotalDrives.text = ""
                
                self?.labelSeparator.backgroundColor = .clear
                self?.labelNoDrivesInThisGroup.isHidden = false
                return
            }
            
            self?.userDrivesList = drives
            self?.tableviewUserDrives.reloadData()
            self?.labelTotalDrives.text = "Total drives: " + drives.count.description
            
            let sortedDrives = drives.sorted(by: { $0.distance > $1.distance })
            guard let longestDrive = sortedDrives.first else { return }
            self?.labelLongestDrive.text = "Longest drive: " + longestDrive.distance.description + " miles"
        }
    }
    
    private func setupUI(user: UserGroup) {
        let imageName = WidgetService.ICON_PREFIX + user.iconId.description
        imageviewUserIcon.image =  UIImage(named: imageName)
        labelPoints.text = "Points: " + user.pointsInGroup.description
        labelTitle.text = "Stats in: " + user.groupName
        labelUsername.text = user.username
    }
    
    private func setupTableView() {
        tableviewUserDrives.dataSource = self
        tableviewUserDrives.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userDrivesList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: DriveTableViewCell.identifier,
                                                        for: indexPath) as! DriveTableViewCell
        resultsCell.configure(with: userDrivesList[indexPath.row])
        return resultsCell
    }
}
