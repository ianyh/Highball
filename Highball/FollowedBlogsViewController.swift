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
		super.init(style: .plain)
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
		refreshControl?.addTarget(self, action: #selector(FollowedBlogsViewController.refresh(_:)), for: .valueChanged)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		guard !dataManager.loading else {
			return
		}

		dataManager.load()
	}

	func refresh(_ sender: UIRefreshControl) {
		dataManager.load()
	}

	func presentError(_ error: NSError) {
		let alertController = UIAlertController(title: "Error", message: "Hit an error trying to load blogs. \(error.localizedDescription)", preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)

		alertController.addAction(action)

		present(alertController, animated: true, completion: nil)

		print(error)
	}
}

// MARK: PostsDataManagerDelegate
extension FollowedBlogsViewController: FollowedBlogsDataManagerDelegate {
	func dataManagerDidReload(_ dataManager: FollowedBlogsDataManager, indexSet: IndexSet?) {
		tableView.reloadData()
	}

	func dataManager(_ dataManager: FollowedBlogsDataManager, didEncounterError error: NSError) {
		presentError(error)
	}
}

// MARK: PostsTableViewAdapterDelegate
extension FollowedBlogsViewController: FollowedBlogsTableViewAdapterDelegate {
	func blogsForAdapter(_ adapter: FollowedBlogsTableViewAdapter) -> [Blog] {
		return dataManager.blogs
	}

	func adapter(_ adapter: FollowedBlogsTableViewAdapter, didSelectBlog blog: Blog) {
		let blogModule = BlogModule(blogName: blog.name, postHeightCache: PostHeightCache())
		blogModule.installInNavigationController(navigationController!)
	}
}
