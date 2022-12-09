//
//  ActivityFeedViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/3/22.
//

import SideMenu
import UIKit

class ActivityFeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                    AccountUpdatesDelegate, EventUpdatesDelegate, GroupUpdatesDelegate {

    private static var eventList: [Event] = []
    private static var hasLoadedData = false
    private static var shouldGetFreshGroups = false
    
    private var refreshControl: UIRefreshControl!
    private var sideMenu: SideMenuNavigationController?

    static var accountUpdatesDelegate: AccountUpdatesDelegate?
    static var eventUpdatesDelegate: EventUpdatesDelegate?
    static var groupUpdatesDelegate: GroupUpdatesDelegate?

    @IBOutlet weak var tableViewActivityFeed: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        if ActivityFeedViewController.shouldGetFreshGroups {
            getFreshGroupsForUser()
            ActivityFeedViewController.shouldGetFreshGroups = false
            return
        }
        
        if !ActivityFeedViewController.hasLoadedData {
            loadTableviewData()
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ActivityFeedViewController.accountUpdatesDelegate = self
        ActivityFeedViewController.eventUpdatesDelegate = self
        ActivityFeedViewController.groupUpdatesDelegate = self
        
        setupSideMenu()
        setupTableView()
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    @objc func refreshTableview(_ sender: Any) {
        getFreshGroupsForUser()
        refreshControl.endRefreshing()
    }
    
    // Uses DatabaseService to getAllGroupsForUser.
    private func getFreshGroupsForUser() {
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        GroupDatabaseService.getAllGroupsForUser(userId: currentUser.userId) { [weak self] error, groupNames in
            guard error == nil && groupNames != [] else {
                return
            }
            
            UserDatabaseService.groupsForCurrentUser = groupNames
            self?.loadTableviewData()
        }
    }
    
    // Gets all events for current user.
    private func loadTableviewData() {
        ActivityFeedViewController.eventList = []

        for groupName in UserDatabaseService.groupsForCurrentUser {

            EventDatabaseService.getEventsForGroup(groupName: groupName) { [weak self] error, events in
                guard error == nil && events.count != 0 else {
                    return
                }

                var newList: [Event] = ActivityFeedViewController.eventList
                newList.append(contentsOf: events)
                                
                let sortedByTimestampList = newList.sorted(by: { $0.timestamp > $1.timestamp })
                ActivityFeedViewController.eventList = sortedByTimestampList
                
                ActivityFeedViewController.hasLoadedData = true
                self?.tableViewActivityFeed.reloadData()
            }
        }
    }
    
    // Sets up navigation side menu.
    private func setupSideMenu() {
        sideMenu = SideMenuNavigationController(rootViewController: SideMenuTableViewController())
        sideMenu?.leftSide = true
        sideMenu?.setNavigationBarHidden(true, animated: true)
        SideMenuManager.default.leftMenuNavigationController = sideMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }
    
    private func setupTableView() {
        tableViewActivityFeed.dataSource = self
        tableViewActivityFeed.delegate = self
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTableview), for: .valueChanged)
        tableViewActivityFeed.addSubview(refreshControl)
    }
    
    func onAccountUpdated() {
        ActivityFeedViewController.hasLoadedData = false
        ActivityFeedViewController.eventList = []
    }
    
    func onEventUpdates() {
        ActivityFeedViewController.hasLoadedData = false
        ActivityFeedViewController.eventList = []
    }
    
    func onGroupUpdates() {
        ActivityFeedViewController.shouldGetFreshGroups = true
        ActivityFeedViewController.eventList = []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ActivityFeedViewController.eventList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultsCell = tableView.dequeueReusableCell(withIdentifier: ActivityFeedTableViewCell.identifier,
                                                        for: indexPath) as! ActivityFeedTableViewCell
        if ActivityFeedViewController.eventList.count != 0 {
            resultsCell.configure(with: ActivityFeedViewController.eventList[indexPath.row])
        }
        
        return resultsCell
    }
}
