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

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        SideMenuTableViewController.selectedRow = selectedIndex

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.separatorColor = .clear
        tableView.backgroundColor = .white
        tableView.allowsMultipleSelection = false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard SideMenuTableViewController.selectedRow != indexPath.row else {
            return
        }
        
        handleNavItemClick(selectedIndex: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.backgroundColor = .white
        
        if indexPath.row == SideMenuTableViewController.selectedRow {
            cell.textLabel?.textColor = .white
        } else {
            cell.textLabel?.textColor = .black
        }
        
        let selectedColor = UIView()
        selectedColor.backgroundColor = UIColor.systemBlue
        cell.selectedBackgroundView = selectedColor
        
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}