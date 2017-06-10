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
	fileprivate var tableView: UITableView!
	fileprivate var accounts: [Account] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		accounts = AccountsService.accounts()

		view.backgroundColor = UIColor.white

		tableView = UITableView()
		tableView.dataSource = self
		tableView.delegate = self
		tableView.allowsSelection = true
		tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)

		view.addSubview(tableView)

		constrain(tableView, view) { tableView, view in
			tableView.edges == view.edges
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return accounts.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let account = accounts[(indexPath as NSIndexPath).row]
		let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier)!

		cell.textLabel?.text = account.name

		if let currentAccount = AccountsService.account {
			if account == currentAccount {
				cell.accessoryType = .checkmark
			} else {
				cell.accessoryType = .none
			}
		}

		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let account = accounts[(indexPath as NSIndexPath).row]

		if let currentAccount = AccountsService.account {
			if account == currentAccount {
				showPasscode(animated: true)
			}
		}

		AccountsService.loginToAccount(account) { _ in
			if let mainViewController = self.presentingViewController as? MainViewController {
				mainViewController.reset()
			}
			self.tableView.reloadData()
			self.showPasscode(animated: true)
		}
	}
}
