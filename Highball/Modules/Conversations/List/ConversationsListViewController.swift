//
//  ConversationsListViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import UIKit

public protocol ConversationsListView: class {
	func reloadView()
}

public class ConversationsListViewController: UITableViewController {
	public var presenter: ConversationsListPresenter?

	public override func viewDidLoad() {
		super.viewDidLoad()

		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}

	public override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		presenter?.viewDidAppear()
	}
}

public extension ConversationsListViewController {
	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return presenter?.numberOfConversations() ?? 0
	}

	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier)!
		let conversation = presenter!.conversationAtIndex(indexPath.row)
		let participantNames = conversation.participants.map { $0.name }

		cell.textLabel?.numberOfLines = 0
		cell.textLabel?.text = participantNames.joinWithSeparator(" + ")

		return cell
	}
}

extension ConversationsListViewController: ConversationsListView {
	public func reloadView() {
		tableView.reloadData()
	}
}
