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
	internal var dashboardPresenter: DashboardPresenter?

	override var presenter: PostsPresenter? {
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

	override init(postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		navigationItem.title = "Dashboard"
		updateRightBarButtonItem()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(applicationWillResignActive(_:)),
			name: NSNotification.Name.UIApplicationWillResignActive,
			object: nil
		)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(
			self,
			name: NSNotification.Name.UIApplicationWillResignActive,
			object: nil
		)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		bookmark()
	}

	func applicationWillResignActive(_ notification: Notification) {
		bookmark()
	}

	func bookmark() {
		guard let firstIndexPath = tableView.indexPathsForVisibleRows?.first else {
			return
		}

		let postIndex = (firstIndexPath as NSIndexPath).section > 0 ? (firstIndexPath as NSIndexPath).section - 1 : (firstIndexPath as NSIndexPath).section

		dashboardPresenter?.bookmarkPostAtIndex(postIndex)
	}

	func bookmarks(_ sender: UIButton, event: UIEvent) {
		let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
			self?.navigationItem.rightBarButtonItem = nil
			self?.presenter?.resetPosts()
			self?.tableViewAdapter?.resetCache()
			self?.tableView.reloadData()
			self?.updateRightBarButtonItem()
		})
		alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}

	func gotoBookmark(_ bookmarkID: Int) {
		dashboardPresenter?.goToBookmarkedPostWithID(bookmarkID)
		tableViewAdapter?.resetCache()
		tableView.reloadData()

		updateRightBarButtonItem()
	}

	func presentHistory(_ sender: AnyObject) {
		let historyViewController = HistoryViewController(delegate: self)
		let navigationController = UINavigationController(rootViewController: historyViewController)

		present(navigationController, animated: true, completion: nil)
	}

	internal func updateRightBarButtonItem() {
		guard let presenter = dashboardPresenter, presenter.isViewingBookmark() else {
			let historyIcon = FAKIonIcons.iosClockOutlineIcon(withSize: 30.0)
			let historyIconImage = historyIcon?.image(with: CGSize(width: 30, height: 30))

			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: historyIconImage,
				style: .plain,
				target: self,
				action: #selector(presentHistory(_:))
			)

			return
		}

		let upArrow = FAKIonIcons.iosArrowUpIcon(withSize: 30)
		let upArrowImage = upArrow?.image(with: CGSize(width: 30, height: 30))

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			image: upArrowImage,
			style: .plain,
			target: self,
			action: #selector(bookmarks(_:event:))
		)
	}
}

extension DashboardViewController: HistoryViewControllerDelegate {
	func historyViewController(_ historyViewController: HistoryViewController, didFinishWithId selectedId: Int?) {
		defer {
			dismiss(animated: true, completion: nil)
		}

		guard let selectedId = selectedId else {
			return
		}

		gotoBookmark(selectedId)
	}
}
