//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        reset()
    }

    func reset() {
        let dashboardViewController = UINavigationController(rootViewController: DashboardViewController())
        let settingsViewController = UINavigationController(rootViewController: SettingsViewController())
        
        dashboardViewController.tabBarItem.title = "Dashboard"
        settingsViewController.tabBarItem.title = "Account"
        
        viewControllers = [dashboardViewController, settingsViewController]
    }
}
