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
	fileprivate var statusBarBackgroundView: UIView!
	fileprivate var observer: AnyObject!
	fileprivate var cachedSelectedIndex: Int = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AccountDidChangeNotification), object: nil, queue: nil) { [unowned self] _ in
			self.reset()
		}

		reset()
	}

	deinit {
		NotificationCenter.default.removeObserver(observer)
	}

	func reset() {
		guard AccountsService.account != nil else {
			viewControllers = [UINavigationController()]
			return
		}

		let postHeightCache = PostHeightCache()

		let dashboardViewController = UINavigationController(rootViewController: DashboardModule(postHeightCache: postHeightCache).viewController)
		let likesViewController = UINavigationController(rootViewController: LikesModule(postHeightCache: postHeightCache).viewController)
		let followedBlogsViewController = UINavigationController(rootViewController: FollowedBlogsViewController())
		let settingsViewController = UINavigationController(rootViewController: SettingsViewController())

		dashboardViewController.tabBarItem.title = "Dashboard"
		dashboardViewController.tabBarItem.image = FAKFontAwesome.homeIcon(withSize: 28.0).image(with: CGSize(width: 28, height: 28))

		likesViewController.tabBarItem.title = "Likes"
		likesViewController.tabBarItem.image = FAKFontAwesome.heartIcon(withSize: 22.0).image(with: CGSize(width: 24, height: 24))

		followedBlogsViewController.tabBarItem.title = "Followed"
		followedBlogsViewController.tabBarItem.image = FAKFontAwesome.usersIcon(withSize: 22.0).image(with: CGSize(width: 24, height: 24))

		settingsViewController.tabBarItem.title = "Settings"
		settingsViewController.tabBarItem.image = FAKFontAwesome.cogsIcon(withSize: 22.0).image(with: CGSize(width: 24, height: 24))

		viewControllers = [
			dashboardViewController,
			likesViewController,
			followedBlogsViewController,
			settingsViewController
		]
	}

	override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		guard let navigationController = selectedViewController as? UINavigationController,
			let tableViewController = navigationController.viewControllers.last as? UITableViewController, selectedIndex == tabBar.items?.index(of: item)
		else {
			return
		}

		cachedSelectedIndex = selectedIndex

		let tableView = tableViewController.tableView
		let currentContentOffsetY = tableView?.contentOffset.y
		let newContentOffsetY = { () -> CGFloat in
			if currentContentOffsetY == -tableView!.contentInset.top {
				return tableView!.contentSize.height - tableView!.bounds.size.height - tableView!.contentInset.top + tableView!.contentInset.bottom
			} else {
				return -tableView!.contentInset.top
			}
		}()

		tableViewController.tableView.setContentOffset(CGPoint(x: 0, y: newContentOffsetY), animated: true)
	}
}
