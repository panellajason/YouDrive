//
//  HomeViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//
import DropDown
import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Dropdown to select a group to show.
    private let groupsDropdown: DropDown = DropDown()
    
    var currentGroupShowing = ""
    var groupsForUser: [String]?
    var hasLoadedData = false
    var passedGroupsForUser: [String] = []
    var usersInGroup: [UserGroup] = []
        
    @IBOutlet weak var buttonChangeShowingGroup: UIButton!
    @IBOutlet weak var labelShowingGroup: UILabel!
    @IBOutlet weak var tableviewShowingGroup: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        // Check if groups for current user have already been populated
        guard passedGroupsForUser == [] else {
            groupsForUser = passedGroupsForUser
            groupsDropdown.dataSource = passedGroupsForUser
            getUsersInGroup(groupName: currentUser.homeGroup)
            
            hasLoadedData = true
            passedGroupsForUser = []
            return
        }
        
        guard hasLoadedData else {
            print("loaded")
            loadDropdownAndTableviewData()
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableviewShowingGroup.dataSource = self
        tableviewShowingGroup.delegate = self
        tableviewShowingGroup.backgroundColor = .white

        setupDropdown()
    }
    
    // Handles on-click for the change group button.
    @IBAction func handleChangeGroupButton(_ sender: Any) {
        groupsDropdown.show()
    }
    
    // Uses DatabaseService to get all users in a group.
    func getUsersInGroup(groupName: String) {
        currentGroupShowing = groupName
        
        GroupDatabaseService.getAllUsersInGroup(groupName: groupName) {[weak self] error, users in
            
            guard error == nil && users.count != 0 else {
                self?.removeSpinner()
                return
            }
            
            self?.labelShowingGroup.text = "Showing group: " + groupName
            self?.usersInGroup = users
            self?.tableviewShowingGroup.reloadData()
            self?.removeSpinner()
        }
    }
    
    // Uses DatabaseService to getAllGroupsForUser and to getUsersInGroup for the selected group in dropdown.
    func loadDropdownAndTableviewData() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        self.showSpinner(onView: self.view)

        GroupDatabaseService.getAllGroupsForUser(userId: currentUser.userId) {[weak self] error, names in
            
            guard error == nil && names != [] else {
                self?.removeSpinner()
                return
            }
            
            self?.groupsForUser = names
            self?.groupsDropdown.dataSource = names
            self?.getUsersInGroup(groupName: currentUser.homeGroup)
            self?.hasLoadedData = true
        }
    }
    
    // Sets up dropdown which displays all the groups that the current user is in.
    func setupDropdown() {
        
        groupsDropdown.anchorView = tableviewShowingGroup
        
        groupsDropdown.selectionAction = {[weak self] index, title in
            
            guard let self = self else { return }
            guard let groups = self.groupsForUser else { return }

            let groupName = groups[index]

            guard groupName != self.currentGroupShowing else {
                return
            }
            
            guard let currentUser = UserDatabaseService.currentUserProfile else { return }
            currentUser.homeGroup = groupName
            
            self.showSpinner(onView: self.view)
            
            UserDatabaseService.updateUserDocument(accountToUpdate: currentUser) { error in
                
                guard error == nil else {
                    return
                }
                
                self.getUsersInGroup(groupName: groupName)
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // segue to player screen??
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        usersInGroup.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: HomeGroupTableViewCell.identifier,
                                                        for: indexPath) as! HomeGroupTableViewCell
        resultsCell.configure(with: usersInGroup[indexPath.row])
        return resultsCell
    }
}
