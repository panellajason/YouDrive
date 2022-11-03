//
//  ActivityFeedViewController.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/3/22.
//

import SideMenu
import UIKit

class ActivityFeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupUpdatesDelegate, EventUpdatesDelegate {

    private static var eventList: [Event] = []
    private static var hasLoadedData = false
    private var sideMenu: SideMenuNavigationController?

    static var eventUpdatesDelegate: EventUpdatesDelegate?

    @IBOutlet weak var tableViewActivityFeed: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !ActivityFeedViewController.hasLoadedData {
            loadTableviewData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ActivityFeedViewController.eventUpdatesDelegate = self

        setupSideMenu()
        setupTableView()
    }
    
    @IBAction func handleSideMenuButton(_ sender: Any) {
        present(sideMenu!, animated: true)
    }
    
    // Uses DatabaseService to getAllGroupsForUser.
    func getFreshGroupsForUser() {
        self.showSpinner(onView: self.view)
        guard let currentUser = UserDatabaseService.currentUserProfile else { return }

        GroupDatabaseService.getAllGroupsForUser(userId: currentUser.userId) {[weak self] error, groupNames in
            
            guard error == nil && groupNames != [] else {
                self?.removeSpinner()
                return
            }
            
            UserDatabaseService.groupsForCurrentUser = groupNames

            ActivityFeedViewController.hasLoadedData = true
            self?.tableViewActivityFeed.reloadData()
            self?.removeSpinner()
        }
    }
    
    // Gets all events for current user.
    func loadTableviewData() {
        self.showSpinner(onView: self.view)
                
        for groupName in UserDatabaseService.groupsForCurrentUser {

            EventDatabaseService.getEventsForGroup(groupName: groupName) { [weak self] error, events in

                guard error == nil && events.count != 0 else {
                    self?.removeSpinner()
                    return
                }

                var newList: [Event] = ActivityFeedViewController.eventList
                newList.append(contentsOf: events)
                                
                let sortedByTimestampList = newList.sorted(by: { $0.timestamp > $1.timestamp })
                ActivityFeedViewController.eventList = sortedByTimestampList
                
                ActivityFeedViewController.hasLoadedData = true
                self?.tableViewActivityFeed.reloadData()
                self?.removeSpinner()
            }
        }
    }
    
    func onGroupUpdates() {
        ActivityFeedViewController.hasLoadedData = false
        ActivityFeedViewController.eventList = []
    }
    
    func onEventUpdates() {
        ActivityFeedViewController.hasLoadedData = false
        ActivityFeedViewController.eventList = []
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
        tableViewActivityFeed.dataSource = self
        tableViewActivityFeed.delegate = self
        tableViewActivityFeed.backgroundColor = .white
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // segue to player screen??
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
        resultsCell.configure(with: ActivityFeedViewController.eventList[indexPath.row])
        return resultsCell
    }
}
