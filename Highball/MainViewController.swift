//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import FontAwesomeKit
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
        dashboardViewController.tabBarItem.image = FAKFontAwesome.homeIconWithSize(28.0).imageWithSize(CGSize(width: 28, height: 28))
//        dashboardViewController.setNavigationBarHidden(true, animated: false)

        likesViewController.tabBarItem.title = "Likes"
        likesViewController.tabBarItem.image = FAKFontAwesome.heartIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))
//        likesViewController.setNavigationBarHidden(true, animated: false)

        historyViewController.tabBarItem.title = "History"
        historyViewController.tabBarItem.image = FAKFontAwesome.historyIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))
//        historyViewController.setNavigationBarHidden(true, animated: false)

        settingsViewController.tabBarItem.title = "Settings"
        settingsViewController.tabBarItem.image = FAKFontAwesome.cogsIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))
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
