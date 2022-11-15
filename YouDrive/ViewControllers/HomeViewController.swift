//
//  HomeViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import DropDown
import SideMenu
import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddDriveDelegate, GroupUpdatesDelegate {
    
    // Dropdown to select a group to show.
    private let groupsDropdown: DropDown = DropDown()
    private var sideMenu: SideMenuNavigationController?
    
    static var groupUpdatesDelegate: GroupUpdatesDelegate?

    var currentGroupShowing = ""
    var groupsForUser: [String]?
    var hasLoadedData = false
    var passedGroupsForUser: [String] = []
    var usersInGroup: [UserGroup] = []
        
    @IBOutlet weak var buttonChangeShowingGroup: UIButton!
    @IBOutlet weak var labelDropdownAnchor: UILabel!
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
            loadDropdownAndTableviewData()
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SideMenuTableViewController.selectedRow = 0
        HomeViewController.groupUpdatesDelegate = self
        setupDropdown()
        setupSideMenu()
        setupTableView()
    }
    
    // Handles on-click for the change group button.
    @IBAction func handleChangeGroupButton(_ sender: Any) {
        groupsDropdown.show()
    }
    
    // Handles on-click for the plus nav bar button.
    @IBAction func handleGoToAddDriveButton(_ sender: Any) {
        self.performSegue(withIdentifier: SegueType.toAddDrive.rawValue, sender: self)
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    // Uses DatabaseService to get all users in a group.
    func getUsersInGroup(groupName: String) {
        currentGroupShowing = groupName
        
        GroupDatabaseService.getAllUsersInGroup(groupName: groupName) {[weak self] error, users in
            
            guard error == nil && users.count != 0 else {
                self?.removeSpinner()
                return
            }
            
            UserDatabaseService.driversForHomeGroup = users
            
            self?.labelShowingGroup.text = "Showing group: " + groupName
            self?.usersInGroup = users
            self?.tableviewShowingGroup.reloadData()
            self?.removeSpinner()
        }
    }
    
    // Handles logic for dropdown selections.
    func handleDropdownSelection(index: Int, title: String) {
        guard let groups = self.groupsForUser else { return }

        let groupName = groups[index]
        guard groupName != self.currentGroupShowing else {
            return
        }
        
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        currentUser.homeGroup = groupName
        
        self.showSpinner(onView: self.view)
        
        UserDatabaseService.updateUserDocument(accountToUpdate: currentUser) { [weak self] error in
            
            guard error == nil else {
                self?.removeSpinner()
                return
            }
            
            self?.getUsersInGroup(groupName: groupName)
            self?.removeSpinner()
        }
    }
    
    // Uses DatabaseService to getAllGroupsForUser and to getUsersInGroup for the selected group in dropdown.
    func loadDropdownAndTableviewData() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        GroupDatabaseService.getAllGroupsForUser(userId: currentUser.userId) {[weak self] error, groupNames in
            
            guard error == nil && groupNames != [] else {
                self?.removeSpinner()
                return
            }
            
            UserDatabaseService.groupsForCurrentUser = groupNames

            self?.groupsForUser = groupNames
            self?.groupsDropdown.dataSource = groupNames
            self?.getUsersInGroup(groupName: currentUser.homeGroup)
            self?.hasLoadedData = true
        }
    }
    
    // Reload data when a new drive is added.
    func onDriveAdded(groupName: String) {
        groupsDropdown.clearSelection()
        getUsersInGroup(groupName: groupName)
    }
    
    // Reload data when a user's groups are updated.
    func onGroupUpdates() {
        hasLoadedData = false
    }
    
    // Sets up dropdown which displays all the groups that the current user is in.
    func setupDropdown() {
        groupsDropdown.anchorView = labelDropdownAnchor
        groupsDropdown.selectionAction = { [weak self] index, title in
            self?.handleDropdownSelection(index: index, title: title)
        }
    }
    
    // Sets up navigation side menu.
    func setupSideMenu() {
        sideMenu = SideMenuNavigationController(rootViewController: SideMenuTableViewController())
        sideMenu?.leftSide = true
        sideMenu?.setNavigationBarHidden(true, animated: true)
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    func setupTableView() {
        tableviewShowingGroup.dataSource = self
        tableviewShowingGroup.delegate = self
        tableviewShowingGroup.backgroundColor = .white
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
    
    // Sets up AddDriveDelegate on segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueType.toAddDrive.rawValue {
            let addDriveViewController = segue.destination as! AddDriveViewController
            addDriveViewController.addDriveDelegate = self
        }
    }
}
