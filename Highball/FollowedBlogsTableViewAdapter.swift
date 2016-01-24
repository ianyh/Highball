//
//  FollowedBlogsTableViewAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/24/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import UIKit

protocol FollowedBlogsTableViewAdapterDelegate {
	func blogsForAdapter(adapter: FollowedBlogsTableViewAdapter) -> [Blog]
	func adapter(adapter: FollowedBlogsTableViewAdapter, didSelectBlog blog: Blog)
}

class FollowedBlogsTableViewAdapter: NSObject {
	private let tableView: UITableView
	private let delegate: FollowedBlogsTableViewAdapterDelegate

	private var blogs: [Blog] {
		return delegate.blogsForAdapter(self)
	}

	init(tableView: UITableView, delegate: FollowedBlogsTableViewAdapterDelegate) {
		self.tableView = tableView
		self.delegate = delegate

		super.init()

		tableView.dataSource = self
		tableView.delegate = self

		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}
}

extension FollowedBlogsTableViewAdapter: UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return blogs.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let blog = blogs[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)

		cell.accessoryType = .DisclosureIndicator
		cell.detailTextLabel?.text = blog.title
		cell.textLabel?.text = blog.name

		return cell
	}
}

extension FollowedBlogsTableViewAdapter: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let blog = blogs[indexPath.row]

		delegate.adapter(self, didSelectBlog: blog)
	}
}
