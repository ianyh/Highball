//
//  FollowedBlogsTableViewAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/24/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import UIKit

protocol FollowedBlogsTableViewAdapterDelegate {
	func blogsForAdapter(_ adapter: FollowedBlogsTableViewAdapter) -> [Blog]
	func adapter(_ adapter: FollowedBlogsTableViewAdapter, didSelectBlog blog: Blog)
}

class FollowedBlogsTableViewAdapter: NSObject {
	fileprivate let tableView: UITableView
	fileprivate let delegate: FollowedBlogsTableViewAdapterDelegate

	fileprivate var blogs: [Blog] {
		return delegate.blogsForAdapter(self)
	}

	init(tableView: UITableView, delegate: FollowedBlogsTableViewAdapterDelegate) {
		self.tableView = tableView
		self.delegate = delegate

		super.init()

		tableView.dataSource = self
		tableView.delegate = self

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}
}

extension FollowedBlogsTableViewAdapter: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return blogs.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let blog = blogs[(indexPath as NSIndexPath).row]
		let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier, for: indexPath)

		cell.accessoryType = .disclosureIndicator
		cell.detailTextLabel?.text = blog.title
		cell.textLabel?.text = blog.name

		return cell
	}
}

extension FollowedBlogsTableViewAdapter: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let blog = blogs[(indexPath as NSIndexPath).row]

		delegate.adapter(self, didSelectBlog: blog)
	}
}
