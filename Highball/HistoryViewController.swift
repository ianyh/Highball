//
//  HistoryViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

public protocol HistoryViewControllerDelegate {
	func historyViewController(historyViewController: HistoryViewController, didFinishWithId selectedId: Int?)
}

public class HistoryViewController: UITableViewController {
	private let delegate: HistoryViewControllerDelegate
	private var bookmarks: [[String: AnyObject]]?

	public init(delegate: HistoryViewControllerDelegate) {
		self.delegate = delegate
		super.init(style: .Plain)
		navigationItem.title = "History"
		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .Cancel,
			target: self,
			action: #selector(cancel(_:))
		)
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}

	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		bookmarks = NSUserDefaults.standardUserDefaults().arrayForKey("HIBookmarks:\(AccountsService.account.primaryBlog.url)") as? [[String: AnyObject]]
		bookmarks = bookmarks?
			.sort { bookmarkA, bookmarkB in
				guard let dateA = bookmarkA["date"] as? NSDate,
					dateB = bookmarkB["date"] as? NSDate
				else {
					return false
				}

				return dateA.compare(dateB) == .OrderedDescending
			}

		tableView.reloadData()
	}

	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return bookmarks?.count ?? 0
	}

	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)
		let bookmark = bookmarks![indexPath.row]

		cell.accessoryType = .DisclosureIndicator
		if let date = bookmark["date"] as? NSDate {
			cell.textLabel?.text = "\(date)"
		} else {
			cell.textLabel?.text = nil
		}

		return cell
	}

	public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let bookmark = bookmarks![indexPath.row]

		guard let bookmarkID = bookmark["id"] as? Int else {
			return
		}

		delegate.historyViewController(self, didFinishWithId: bookmarkID)
	}

	public func cancel(sender: AnyObject) {
		delegate.historyViewController(self, didFinishWithId: nil)
	}
}
