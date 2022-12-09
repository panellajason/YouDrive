//
//  NavigationService.swift
//  YouDrive
//
//  Created by Panella, Jason on 11/2/22.
//

import Foundation
import UIKit

class NavigationService {
    
    static let storyboard = UIStoryboard(name: "Main", bundle: nil)

    static var mainNavController = UINavigationController()
    
    static func showMainNavController(shouldPassGroups: Bool) {
        // Nav controller
        let navController = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as? UINavigationController
        NavigationService.mainNavController = navController!
        
        // Set root view controller
        NavigationService.setRootViewController(rootViewController: navController)

        // Home view controller
        let viewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        if shouldPassGroups {
            viewController.passedGroupsForUser = UserDatabaseService.groupsForCurrentUser
        }
        navController?.pushViewController(viewController, animated: true)
    }
    
    static func showNoGroupsViewController() {
        let noGroupsViewController = storyboard.instantiateViewController(withIdentifier: "NoGroupsViewController") as? NoGroupsViewController
        NavigationService.setRootViewController(rootViewController: noGroupsViewController)
    }
    
    static func showSignInViewController() {
        let signInViewController = storyboard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController
        NavigationService.setRootViewController(rootViewController: signInViewController)
    }
    
    private static func setRootViewController(rootViewController: UIViewController?) {
        UIApplication.shared.windows.first?.rootViewController = rootViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}
