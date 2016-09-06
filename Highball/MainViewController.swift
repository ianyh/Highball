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
		guard AccountsService.account != nil else {
			viewControllers = [UINavigationController()]
			return
		}

		let postHeightCache = PostHeightCache()

		let dashboardViewController = UINavigationController(rootViewController: DashboardModule(postHeightCache: postHeightCache).viewController)
		let likesViewController = UINavigationController(rootViewController: LikesModule(postHeightCache: postHeightCache).viewController)
		let followedBlogsViewController = UINavigationController(rootViewController: ConversationsListModule().viewController)
		let settingsViewController = UINavigationController(rootViewController: SettingsViewController())

		dashboardViewController.tabBarItem.title = "Dashboard"
		dashboardViewController.tabBarItem.image = FAKFontAwesome.homeIconWithSize(28.0).imageWithSize(CGSize(width: 28, height: 28))

		likesViewController.tabBarItem.title = "Likes"
		likesViewController.tabBarItem.image = FAKFontAwesome.heartIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		followedBlogsViewController.tabBarItem.title = "Followed"
		followedBlogsViewController.tabBarItem.image = FAKFontAwesome.usersIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		settingsViewController.tabBarItem.title = "Settings"
		settingsViewController.tabBarItem.image = FAKFontAwesome.cogsIconWithSize(22.0).imageWithSize(CGSize(width: 24, height: 24))

		viewControllers = [
			dashboardViewController,
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
//
//		let webView = UIWebView()
//		view.addSubview(webView)
//		webView.frame = view.bounds
//
//		let urlRequest = NSMutableURLRequest(URL: NSURL(string: "https://www.tumblr.com/svc/conversations?participant=thatseemsright.tumblr.com&_=1473105812470")!)
//		urlRequest.addValue("i7Wi4kwmh6ebC8jKpdV4xMUGcFA", forHTTPHeaderField: "X-tumblr-form-key")
//		urlRequest.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
//		webView.loadRequest(urlRequest)
//
//		webView.delegate = self
	}

	private func resetStatusBarFrame() {
		statusBarBackgroundView.frame = UIApplication.sharedApplication().statusBarFrame
	}

	override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
		guard let navigationController = selectedViewController as? UINavigationController,
			tableViewController = navigationController.viewControllers.last as? UITableViewController
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
