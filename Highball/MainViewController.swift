//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {
    private var statusBarBackgroundView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        reset()
    }

    func reset() {
        let dashboardViewController = UINavigationController(rootViewController: DashboardViewController())
        let likesViewController = UINavigationController(rootViewController: LikesViewController())
        let historyViewController = UINavigationController(rootViewController: HistoryViewController(delegate: self))
        let settingsViewController = UINavigationController(rootViewController: SettingsViewController())
        
        dashboardViewController.tabBarItem.title = "Dashboard"
//        dashboardViewController.setNavigationBarHidden(true, animated: false)

        likesViewController.tabBarItem.title = "Likes"
//        likesViewController.setNavigationBarHidden(true, animated: false)

        historyViewController.tabBarItem.title = "History"
//        historyViewController.setNavigationBarHidden(true, animated: false)

        settingsViewController.tabBarItem.title = "Account"
//        settingsViewController.setNavigationBarHidden(true, animated: false)
        
        viewControllers = [
            dashboardViewController,
            likesViewController,
            historyViewController,
            settingsViewController
        ]

        statusBarBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))

//        view.addSubview(statusBarBackgroundView)

        NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationWillChangeStatusBarFrameNotification,
            object:
            self,
            queue: nil
        ) { [unowned self] _ in
            self.resetStatusBarFrame()
        }

        resetStatusBarFrame()
    }

    private func resetStatusBarFrame() {
        statusBarBackgroundView.frame = UIApplication.sharedApplication().statusBarFrame
    }
}

extension MainViewController: HistoryViewControllerDelegate {
    func historyViewController(historyViewController: HistoryViewController, selectedId: Int) {
        let dashboardViewController = viewControllers![0] as! UINavigationController

        dashboardViewController.popToRootViewControllerAnimated(false)
        (dashboardViewController.topViewController as! DashboardViewController).gotoBookmark(selectedId)

        selectedIndex = 0
    }
}
