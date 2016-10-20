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
		let followedBlogsViewController = UINavigationController(rootViewController: ConversationsListModule().viewController)
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

		statusBarBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

//        view.addSubview(statusBarBackgroundView)

		NotificationCenter.default.addObserver(
			forName: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
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

	fileprivate func resetStatusBarFrame() {
		statusBarBackgroundView.frame = UIApplication.shared.statusBarFrame
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
