//
//  LockSplashViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/8/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import VENTouchLock

class LockSplashViewController: VENTouchLockSplashViewController, UITableViewDataSource, UITableViewDelegate {
	private var tableView: UITableView!
	private var accounts: Array<Account>!

	override func viewDidLoad() {
		super.viewDidLoad()

		accounts = AccountsService.accounts()

		view.backgroundColor = UIColor.whiteColor()

		tableView = UITableView()
		tableView.dataSource = self
		tableView.delegate = self
		tableView.allowsSelection = true
		tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)

		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)

		view.addSubview(tableView)

		constrain(tableView, view) { tableView, view in
			tableView.edges == view.edges
		}
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return accounts.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let account = accounts[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier)!

		cell.textLabel?.text = account.name

		if let currentAccount = AccountsService.account {
			if account == currentAccount {
				cell.accessoryType = .Checkmark
			} else {
				cell.accessoryType = .None
			}
		}

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let account = accounts[indexPath.row]

		if let currentAccount = AccountsService.account {
			if account == currentAccount {
				showPasscodeAnimated(true)
			}
		}

		AccountsService.loginToAccount(account) { _ in
			if let mainViewController = self.presentingViewController as? MainViewController {
				mainViewController.reset()
			}
			self.tableView.reloadData()
			self.showPasscodeAnimated(true)
		}
	}
}
