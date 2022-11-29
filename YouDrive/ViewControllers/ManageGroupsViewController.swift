//
//  ManageGroupsViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/2/22.
//

import DropDown
import SideMenu
import UIKit

class ManageGroupsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupUpdatesDelegate {

    private let moreOptionsDropdown: DropDown = DropDown()
    
    private var groupsList: [String] = []
    private var selectedGroupName: String?
    private var sideMenu: SideMenuNavigationController?

    static var groupUpdatesDelegate: GroupUpdatesDelegate?

    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var tableViewManageGroups: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ManageGroupsViewController.groupUpdatesDelegate = self
        
        groupsList = UserDatabaseService.groupsForCurrentUser
        setupDropdown()
        setupTableView()
        setupSideMenu()
    }
    
    // Handles on-click for the more options button.
    @IBAction func handleMoreButton(_ sender: Any) {
        moreOptionsDropdown.show()
        moreOptionsDropdown.clearSelection()
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    // Uses DatabaseService to getAllGroupsForUser.
    func getFreshGroupsForUser() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }
        GroupDatabaseService.getAllGroupsForUser(userId: currentUser.userId) { [weak self] error, groupNames in
            guard error == nil && groupNames != [] else { return }
            self?.groupsList = groupNames
            self?.tableViewManageGroups.reloadData()
        }
    }
    
    private func handleDropdownSelection(title: String) {
        var viewController: UIViewController
        if title == ManageGroupOptions.CreateGroup.rawValue {
            viewController = storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        } else {
            viewController = storyboard?.instantiateViewController(withIdentifier: "JoinGroupViewController") as! JoinGroupViewController
        }
        
        present(viewController, animated: true)
    }
    
    // Reload data when a user's groups are updated.
    func onGroupUpdates() {
        getFreshGroupsForUser()
    }
    
    // Sets up navigation side menu.
    private func setupSideMenu() {
        sideMenu = SideMenuNavigationController(rootViewController: SideMenuTableViewController())
        sideMenu?.leftSide = true
        sideMenu?.setNavigationBarHidden(true, animated: true)
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    // Sets up dropdown which displays create and join group buttons.
    private func setupDropdown() {
        moreOptionsDropdown.anchorView = moreButton
        moreOptionsDropdown.bottomOffset = CGPoint(x: CGFloat(0), y: CGFloat(35))
        moreOptionsDropdown.backgroundColor = .darkGray
        moreOptionsDropdown.separatorColor = .black
        moreOptionsDropdown.textColor = .white
        moreOptionsDropdown.dataSource = [ManageGroupOptions.CreateGroup.rawValue, ManageGroupOptions.JoinGroup.rawValue]
        moreOptionsDropdown.selectionAction = { [weak self] index, title in
            self?.handleDropdownSelection(title: title)
        }
    }
    
    private func setupTableView() {
        tableViewManageGroups.dataSource = self
        tableViewManageGroups.delegate = self
        tableViewManageGroups.backgroundColor = .white
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedGroupName = groupsList[indexPath.row]
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueType.toGroupDetail.rawValue {
            let GroupDetailViewController = segue.destination as! GroupDetailViewController
            GroupDetailViewController.passedGroupName = selectedGroupName
        }
    }
}
