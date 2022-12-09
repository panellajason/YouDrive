//
//  HomeViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/15/22.
//

import DropDown
import SideMenu
import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AccountUpdatesDelegate, AddDriveDelegate, GroupUpdatesDelegate {
    
    // Dropdown to select a group to show.
    private let groupsDropdown: DropDown = DropDown()
    
    private var refreshControl: UIRefreshControl!
    private var selectedUser: UserGroup?
    private var sideMenu: SideMenuNavigationController?
    
    static var accountUpdatesDelegate: AccountUpdatesDelegate?
    static var groupUpdatesDelegate: GroupUpdatesDelegate?
    
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
        self.title = "You-Drive"

        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        // Check if groups for current user have already been populated
        guard passedGroupsForUser == [] else {
            groupsForUser = passedGroupsForUser
            groupsDropdown.dataSource = passedGroupsForUser
            groupsDropdown.selectRow(at: passedGroupsForUser.firstIndex(of: currentUser.homeGroup))
            getUsersInGroup(groupName: currentUser.homeGroup)
            
            checkIfChangeButtonShouldBeHidden(groupNames: passedGroupsForUser)

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
        HomeViewController.accountUpdatesDelegate = self
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
    
    @objc func refreshTableview(_ sender: Any) {
        loadDropdownAndTableviewData()
        refreshControl.endRefreshing()
    }
    
    private func checkIfChangeButtonShouldBeHidden(groupNames: [String]) {
        buttonChangeShowingGroup.isHidden = groupNames.count < 2 ? true : false
        UserDatabaseService.hasReachedMaxGroups = groupNames.count > 10 ? true : false
    }
    
    // Uses DatabaseService to get all users in a group.
    private func getUsersInGroup(groupName: String) {
        currentGroupShowing = groupName
        
        GroupDatabaseService.getAllUsersInGroup(groupName: groupName) {[weak self] error, users in
            self?.removeSpinner()
            guard error == nil && users.count != 0 else { return }
            
            UserDatabaseService.driversForHomeGroup = users
            
            self?.labelShowingGroup.text = "Showing group: " + groupName
            self?.usersInGroup = users
            self?.tableviewShowingGroup.reloadData()
        }
    }
    
    // Handles logic for dropdown selections.
    func handleDropdownSelection(index: Int, title: String) {
        guard let groups = self.groupsForUser else { return }
        let groupName = groups[index]
        guard groupName != self.currentGroupShowing else { return }
    
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        currentUser.homeGroup = groupName
        
        self.showSpinner(onView: self.view)
        UserDatabaseService.updateUserDocument(accountToUpdate: currentUser, batch: nil) { [weak self] error, batch in
            self?.removeSpinner()
            guard error == nil else { return }
            self?.getUsersInGroup(groupName: groupName)
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
            self?.groupsDropdown.selectRow(at: groupNames.firstIndex(of: currentUser.homeGroup))
            self?.getUsersInGroup(groupName: currentUser.homeGroup)
            self?.hasLoadedData = true
            self?.checkIfChangeButtonShouldBeHidden(groupNames: groupNames)
        }
    }
    
    // Reload data when account is updated.
    func onAccountUpdated() {
        hasLoadedData = false
    }
    
    // Reload data when a new drive is added.
    func onDriveAdded(groupName: String) {
        getUsersInGroup(groupName: groupName)
    }
    
    // Reload data when a user's groups are updated.
    func onGroupUpdates() {
        hasLoadedData = false
    }
    
    // Sets up dropdown which displays all the groups that the current user is in.
    func setupDropdown() {
        groupsDropdown.anchorView = buttonChangeShowingGroup
        groupsDropdown.bottomOffset = CGPoint(x: CGFloat(-8), y: CGFloat(32))
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
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTableview), for: .valueChanged)
        tableviewShowingGroup.addSubview(refreshControl)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUser = usersInGroup[indexPath.row]
        self.performSegue(withIdentifier: SegueType.toUserDetail.rawValue, sender: self)
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
        
        if segue.identifier == SegueType.toUserDetail.rawValue {
            let userDetailViewController = segue.destination as! UserDetailViewController
            userDetailViewController.passedUser = selectedUser
        }
    }
}
