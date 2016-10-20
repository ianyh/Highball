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

open class ConversationsListViewController: UITableViewController {
	open var presenter: ConversationsListPresenter?

	open override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		presenter?.viewDidAppear()
	}

	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return presenter?.numberOfConversations() ?? 0
	}

	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier)!
		let conversation = presenter!.conversationAtIndex((indexPath as NSIndexPath).row)
		let participantNames = conversation.participants.map { $0.name }

		cell.textLabel?.numberOfLines = 0
		cell.textLabel?.text = participantNames.joined(separator: " + ")

		return cell
	}
}

extension ConversationsListViewController: ConversationsListView {
	public func reloadView() {
		tableView.reloadData()
	}
}
