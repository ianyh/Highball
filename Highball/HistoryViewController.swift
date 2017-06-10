//
//  HistoryViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

protocol HistoryViewControllerDelegate: class {
	func historyViewController(_ historyViewController: HistoryViewController, didFinishWithId selectedId: Int?)
}

class HistoryViewController: UITableViewController {
	fileprivate let delegate: HistoryViewControllerDelegate
	fileprivate var bookmarks: [[String: AnyObject]]?

	init(delegate: HistoryViewControllerDelegate) {
		self.delegate = delegate
		super.init(style: .plain)
		navigationItem.title = "History"
		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel,
			target: self,
			action: #selector(cancel(_:))
		)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		bookmarks = UserDefaults.standard.array(forKey: "HIBookmarks:\(AccountsService.account.primaryBlog.url)") as? [[String: AnyObject]]
		bookmarks = bookmarks?
			.sorted { bookmarkA, bookmarkB in
				guard let dateA = bookmarkA["date"] as? Date,
					let dateB = bookmarkB["date"] as? Date
				else {
					return false
				}

				return dateA.compare(dateB) == .orderedDescending
			}

		tableView.reloadData()
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return bookmarks?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier, for: indexPath)
		let bookmark = bookmarks![(indexPath as NSIndexPath).row]

		cell.accessoryType = .disclosureIndicator
		if let date = bookmark["date"] as? Date {
			cell.textLabel?.text = "\(date)"
		} else {
			cell.textLabel?.text = nil
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let bookmark = bookmarks![(indexPath as NSIndexPath).row]

		guard let bookmarkID = bookmark["id"] as? Int else {
			return
		}

		delegate.historyViewController(self, didFinishWithId: bookmarkID)
	}

	func cancel(_ sender: AnyObject) {
		delegate.historyViewController(self, didFinishWithId: nil)
	}
}
