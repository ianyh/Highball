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

public class DashboardViewController: PostsViewController {
	internal var dashboardPresenter: DashboardPresenter?

	public override weak var presenter: PostsPresenter? {
		get {
			return dashboardPresenter as? PostsPresenter
		}
		set {
			guard let presenter = newValue as? DashboardPresenter else {
				fatalError()
			}

			dashboardPresenter = presenter
		}
	}

	public override init(postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		navigationItem.title = "Dashboard"
		updateRightBarButtonItem()

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(applicationWillResignActive(_:)),
			name: UIApplicationWillResignActiveNotification,
			object: nil
		)
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(
			self,
			name: UIApplicationWillResignActiveNotification,
			object: nil
		)
	}

	public override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

		bookmark()
	}

	public func applicationWillResignActive(notification: NSNotification) {
		bookmark()
	}

	public func bookmark() {
		guard let firstIndexPath = tableView.indexPathsForVisibleRows?.first else {
			return
		}

		let postIndex = firstIndexPath.section > 0 ? firstIndexPath.section - 1 : firstIndexPath.section

		dashboardPresenter?.bookmarkPostAtIndex(postIndex)
	}

	public func bookmarks(sender: UIButton, event: UIEvent) {
		let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "Yes", style: .Default) { [weak self] action in
			self?.navigationItem.rightBarButtonItem = nil
			self?.presenter?.resetPosts()
			self?.tableViewAdapter?.resetCache()
			self?.tableView.reloadData()
			self?.updateRightBarButtonItem()
		})
		alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
		presentViewController(alertController, animated: true, completion: nil)
	}

	public func gotoBookmark(bookmarkID: Int) {
		dashboardPresenter?.goToBookmarkedPostWithID(bookmarkID)
		tableViewAdapter?.resetCache()
		tableView.reloadData()

		updateRightBarButtonItem()
	}

	public func presentHistory(sender: AnyObject) {
		let historyViewController = HistoryViewController(delegate: self)
		let navigationController = UINavigationController(rootViewController: historyViewController)

		presentViewController(navigationController, animated: true, completion: nil)
	}

	internal func updateRightBarButtonItem() {
		guard let presenter = dashboardPresenter where presenter.isViewingBookmark() else {
			let historyIcon = FAKIonIcons.iosClockOutlineIconWithSize(30.0)
			let historyIconImage = historyIcon.imageWithSize(CGSize(width: 30, height: 30))

			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: historyIconImage,
				style: .Plain,
				target: self,
				action: #selector(presentHistory(_:))
			)

			return
		}

		let upArrow = FAKIonIcons.iosArrowUpIconWithSize(30)
		let upArrowImage = upArrow.imageWithSize(CGSize(width: 30, height: 30))

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			image: upArrowImage,
			style: .Plain,
			target: self,
			action: #selector(bookmarks(_:event:))
		)
	}
}

extension DashboardViewController: HistoryViewControllerDelegate {
	public func historyViewController(historyViewController: HistoryViewController, didFinishWithId selectedId: Int?) {
		defer {
			dismissViewControllerAnimated(true, completion: nil)
		}

		guard let selectedId = selectedId else {
			return
		}

		gotoBookmark(selectedId)
	}
}
