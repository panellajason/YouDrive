//
//  SideMenuTableViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 10/30/22.
//

import UIKit

class SideMenuTableViewController: UITableViewController {

    static var selectedRow = 0

    var menuItems: [String] = [SideBarNavItem.Home.rawValue, SideBarNavItem.ActivityFeed.rawValue, SideBarNavItem.ManageGroups.rawValue, SideBarNavItem.Account.rawValue]
    
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

        switch selectedIndex {
            
        case menuItems.firstIndex(of: SideBarNavItem.Home.rawValue):
            let homeVc = NavigationService.storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            homeVc.passedGroupsForUser = UserDatabaseService.groupsForCurrentUser
            NavigationService.mainNavController.popViewController(animated: false)
            break
        
        case menuItems.firstIndex(of: SideBarNavItem.ActivityFeed.rawValue):
            NavigationService.mainNavController.popViewController(animated: false)
            let viewController = NavigationService.storyboard.instantiateViewController(withIdentifier: "ActivityFeedViewController") as! ActivityFeedViewController
            NavigationService.mainNavController.pushViewController(viewController, animated: false)
            break
            
        case menuItems.firstIndex(of: SideBarNavItem.ManageGroups.rawValue):
            NavigationService.mainNavController.popViewController(animated: false)
            let viewController = NavigationService.storyboard.instantiateViewController(withIdentifier: "ManageGroupsViewController") as! ManageGroupsViewController
            NavigationService.mainNavController.pushViewController(viewController, animated: false)
            break
            
        case menuItems.firstIndex(of: SideBarNavItem.Account.rawValue):
            NavigationService.mainNavController.popViewController(animated: false)
            let viewController = NavigationService.storyboard.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
            NavigationService.mainNavController.pushViewController(viewController, animated: false)
            break
        
        default:
            return
        }
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "SideMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "SideMenuTableViewCell")
        tableView.separatorColor = .clear
        tableView.backgroundColor = .systemGray5
        tableView.bounces = false
        tableView.allowsMultipleSelection = false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard SideMenuTableViewController.selectedRow != indexPath.row else { return }
        handleNavItemClick(selectedIndex: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: SideMenuTableViewCell.identifier,
                                                    for: indexPath) as! SideMenuTableViewCell
        resultsCell.configure(with: menuItems[indexPath.row])
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemBlue
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
