//
//  SideMenuTableViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/30/22.
//

import UIKit

class SideMenuTableViewController: UITableViewController {

    var menuItems: [String] = [SideBarNavItem.Home.rawValue, SideBarNavItem.ActivityFeed.rawValue, SideBarNavItem.ManageGroups.rawValue, SideBarNavItem.SignOut.rawValue]

    static var selectedRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let indexPath = IndexPath(row: SideMenuTableViewController.selectedRow, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
    }
    
    
    
    private func handleNavItemClick(selectedIndex: Int) {
        self.dismiss(animated: true)
        SideMenuTableViewController.selectedRow = selectedIndex
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch selectedIndex {
            
        case menuItems.firstIndex(of: SideBarNavItem.Home.rawValue):
            let homeVc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            homeVc.passedGroupsForUser = UserDatabaseService.groupsForCurrentUser
            NavigationService.mainNavController.popViewController(animated: false)
            break
        
        case menuItems.firstIndex(of: SideBarNavItem.ActivityFeed.rawValue):
            NavigationService.mainNavController.popViewController(animated: false)
            let viewController = storyboard.instantiateViewController(withIdentifier: "ActivityFeedViewController") as! ActivityFeedViewController
            NavigationService.mainNavController.pushViewController(viewController, animated: false)
            break
            
        case menuItems.firstIndex(of: SideBarNavItem.ManageGroups.rawValue):
            NavigationService.mainNavController.popViewController(animated: false)
            let viewController = storyboard.instantiateViewController(withIdentifier: "ManageGroupsViewController") as! ManageGroupsViewController
            NavigationService.mainNavController.pushViewController(viewController, animated: false)
            break
        
        case menuItems.firstIndex(of: SideBarNavItem.SignOut.rawValue):
            UserDatabaseService.handleSignOut()
            break
        default:
            return
        }
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "SideMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "SideMenuTableViewCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.separatorColor = .clear
        tableView.backgroundColor = .white
        tableView.bounces = false
        tableView.allowsMultipleSelection = false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard SideMenuTableViewController.selectedRow != indexPath.row else {
            return
        }
        
        handleNavItemClick(selectedIndex: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: SideMenuTableViewCell.identifier,
                                                    for: indexPath) as! SideMenuTableViewCell
        resultsCell.configure(with: menuItems[indexPath.row])
        let backgroundView = UIView()
        backgroundView.backgroundColor = .lightGray
        resultsCell.selectedBackgroundView = backgroundView
        return resultsCell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
