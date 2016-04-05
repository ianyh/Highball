//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import ChameleonFramework
import FontAwesomeKit
import UIKit

class MainViewController: UITabBarController {
	private var statusBarBackgroundView: UIView!
	private var observer: AnyObject!
	private var cachedSelectedIndex: Int = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		observer = NSNotificationCenter.defaultCenter().addObserverForName(AccountDidChangeNotification, object: nil, queue: nil) { [unowned self] _ in
			self.reset()
		}

		reset()
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(observer)
	}

	func reset() {
		let dashboardViewController = UINavigationController(rootViewController: DashboardViewController())
		let historyViewController = UINavigationController(rootViewController: HistoryViewController(delegate: self))
		let likesViewController = UINavigationController(rootViewController: LikesViewController())
		let followedBlogsViewController = UINavigationController(rootViewController: FollowedBlogsViewController())
		let settingsViewController = UINavigationController(rootViewController: SettingsViewController())

		dashboardViewController.tabBarItem.title = "Dashboard"
		dashboardViewController.tabBarItem.image = FAKFontAwesome.homeIconWithSize(28.0).imageWithSize(CGSize(width: 28, height: 28))

		historyViewController.tabBarItem.title = "History"
		historyViewController.tabBarItem.image = FAKFontAwesome.historyIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		likesViewController.tabBarItem.title = "Likes"
		likesViewController.tabBarItem.image = FAKFontAwesome.heartIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		followedBlogsViewController.tabBarItem.title = "Followed"
		followedBlogsViewController.tabBarItem.image = FAKFontAwesome.usersIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		settingsViewController.tabBarItem.title = "Settings"
		settingsViewController.tabBarItem.image = FAKFontAwesome.cogsIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		viewControllers = [
			dashboardViewController,
			historyViewController,
			likesViewController,
			followedBlogsViewController,
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

		selectedIndex = 0
	}

	private func resetStatusBarFrame() {
		statusBarBackgroundView.frame = UIApplication.sharedApplication().statusBarFrame
	}

	override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
		guard
			let navigationController = selectedViewController as? UINavigationController,
			let tableViewController = navigationController.viewControllers.last as? UITableViewController
			where selectedIndex == tabBar.items?.indexOf(item)
		else {
			return
		}

		cachedSelectedIndex = selectedIndex

		let tableView = tableViewController.tableView
		let currentContentOffsetY = tableView.contentOffset.y
		let newContentOffsetY = { () -> CGFloat in
			if currentContentOffsetY == -tableView.contentInset.top {
				return tableView.contentSize.height - tableView.bounds.size.height - tableView.contentInset.top + tableView.contentInset.bottom
			} else {
				return -tableView.contentInset.top
			}
		}()

		tableViewController.tableView.setContentOffset(CGPoint(x: 0, y: newContentOffsetY), animated: true)
	}
}

extension MainViewController: HistoryViewControllerDelegate {
	func historyViewController(historyViewController: HistoryViewController, selectedId: Int) {
		let dashboardViewController = viewControllers![0] as! UINavigationController

		dashboardViewController.popToRootViewControllerAnimated(false)
		(dashboardViewController.topViewController as! DashboardViewController).gotoBookmark(selectedId)

		cachedSelectedIndex = 0
		selectedIndex = 0
	}
}
