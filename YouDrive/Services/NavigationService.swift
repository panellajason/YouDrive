//
//  NavigationService.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/2/22.
//

import Foundation
import UIKit

class NavigationService {
    
    static var mainNavController = UINavigationController()

    
    static func showMainNavController () {
        // Nav controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as? UINavigationController
        NavigationService.mainNavController = navController!
        
        // Set root view controller
        UIApplication.shared.windows.first?.rootViewController = navController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
        
        // Home view controller
        let viewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        viewController.passedGroupsForUser = UserDatabaseService.groupsForCurrentUser
        navController?.pushViewController(viewController, animated: true)   
    }
}
