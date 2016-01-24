//
//  FollowedBlogsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/24/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import UIKit

class FollowedBlogsViewController: UITableViewController {
	var tableViewAdapter: FollowedBlogsTableViewAdapter?
	var dataManager: FollowedBlogsDataManager!

	init() {
		super.init(style: .Plain)
		self.dataManager = FollowedBlogsDataManager(delegate: self)

		navigationItem.title = "Followed"
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableViewAdapter = FollowedBlogsTableViewAdapter(tableView: tableView, delegate: self)

		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard !dataManager.loading else {
			return
		}

		dataManager.load()
	}

	func refresh(sender: UIRefreshControl) {
		dataManager.load()
	}

	func presentError(error: NSError) {
		let alertController = UIAlertController(title: "Error", message: "Hit an error trying to load blogs. \(error.localizedDescription)", preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)

		alertController.addAction(action)

		presentViewController(alertController, animated: true, completion: nil)

		print(error)
	}
}

// MARK: PostsDataManagerDelegate
extension FollowedBlogsViewController: FollowedBlogsDataManagerDelegate {
	func dataManagerDidReload(dataManager: FollowedBlogsDataManager, indexSet: NSIndexSet?) {
		tableView.reloadData()
	}

	func dataManager(dataManager: FollowedBlogsDataManager, didEncounterError error: NSError) {
		presentError(error)
	}
}

// MARK: PostsTableViewAdapterDelegate
extension FollowedBlogsViewController: FollowedBlogsTableViewAdapterDelegate {
	func blogsForAdapter(adapter: FollowedBlogsTableViewAdapter) -> [Blog] {
		return dataManager.blogs ?? []
	}

	func adapter(adapter: FollowedBlogsTableViewAdapter, didSelectBlog blog: Blog) {
		let blogViewController = BlogViewController(blogName: blog.name)

		navigationController?.pushViewController(blogViewController, animated: true)
	}
}
