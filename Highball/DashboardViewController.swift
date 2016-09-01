//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import FontAwesomeKit
import Mapper
import SwiftyJSON
import TMTumblrSDK
import UIKit

class DashboardViewController: PostsViewController {
	override init() {
		super.init()

		navigationItem.title = "Dashboard"
		updateRightBarButtonItem()

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)),
			name: UIApplicationWillResignActiveNotification,
			object: nil
		)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(
			self,
			name: UIApplicationWillResignActiveNotification,
			object: nil
		)
	}

	override func viewDidDisappear(animated: Bool) {
		self.bookmark()
	}

	override func postsFromJSON(json: JSON) -> Array<Post> {
		guard let postsJSON = json["posts"].array else {
			return []
		}

		return postsJSON.map { Post.from($0.dictionaryObject!) }.flatMap { $0 }
	}

	override func requestPosts(postCount: Int, parameters: [String: AnyObject], callback: TMAPICallback) {
		TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
	}

	func applicationWillResignActive(notification: NSNotification) {
		bookmark()
	}

	func bookmark() {
		guard let indexPaths = tableView.indexPathsForVisibleRows,
			firstIndexPath = indexPaths.first,
			account = AccountsService.account
		else {
			return
		}

		let userDefaults = NSUserDefaults.standardUserDefaults()
		let bookmarksKey = "HIBookmarks:\(account.primaryBlog.url)"
		let postIndex = firstIndexPath.section > 0 ? firstIndexPath.section - 1 : firstIndexPath.section
		let post = dataManager.posts[postIndex]
		var bookmarks: [[String: AnyObject]] = userDefaults.arrayForKey(bookmarksKey) as? [[String: AnyObject]] ?? []

		bookmarks.insert(["date": NSDate(), "id": post.id], atIndex: 0)

		if bookmarks.count > 20 {
			bookmarks = [[String: AnyObject]](bookmarks.prefix(20))
		}

		userDefaults.setObject(bookmarks, forKey: bookmarksKey)
	}

	func bookmarks(sender: UIButton, event: UIEvent) {
		guard dataManager.topID != nil else {
			return
		}

		let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "Yes", style: .Default) { action  in
			self.navigationItem.rightBarButtonItem = nil
			self.dataManager.topID = nil
			self.dataManager.posts = []
			self.tableViewAdapter?.resetCache()
			self.tableView.reloadData()
			self.dataManager.loadTop(self.tableView.frame.width)
			self.updateRightBarButtonItem()
		})
		alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
		presentViewController(alertController, animated: true, completion: nil)
	}

	func gotoBookmark(bookmarkID: Int) {
		dataManager.topID = bookmarkID
		dataManager.cursor = bookmarkID
		dataManager.posts = []
		dataManager.loadMore(tableView.frame.width)
		tableViewAdapter?.resetCache()
		tableView.reloadData()

		updateRightBarButtonItem()
	}

	func presentHistory() {
		let historyViewController = HistoryViewController(delegate: self)
		let navigationController = UINavigationController(rootViewController: historyViewController)

		presentViewController(navigationController, animated: true, completion: nil)
	}

	internal func updateRightBarButtonItem() {
		if dataManager.topID == nil {
			let historyIcon = FAKIonIcons.iosClockOutlineIconWithSize(30.0)
			let historyIconImage = historyIcon.imageWithSize(CGSize(width: 30, height: 30))

			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: historyIconImage,
				style: .Plain,
				target: self,
				action: #selector(presentHistory)
			)
		} else {
			let upArrow = FAKIonIcons.iosArrowUpIconWithSize(30)
			let upArrowImage = upArrow.imageWithSize(CGSize(width: 30, height: 30))

			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: upArrowImage,
				style: .Plain,
				target: self,
				action: #selector(DashboardViewController.bookmarks(_:event:))
			)
		}
	}
}

extension DashboardViewController: HistoryViewControllerDelegate {
	func historyViewController(historyViewController: HistoryViewController, didFinishWithId selectedId: Int?) {
		defer {
			dismissViewControllerAnimated(true, completion: nil)
		}

		guard let selectedId = selectedId else {
			return
		}

		gotoBookmark(selectedId)
	}
}
