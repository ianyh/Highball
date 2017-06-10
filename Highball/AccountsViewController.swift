//
//  AccountsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/16/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

// swiftlint:disable variable_name
let AccountDidChangeNotification = "AccountDidChangeNotification"
// swiftlint:enable variable_name

class AccountsViewController: UITableViewController {
	fileprivate enum Section: Int {
		case accounts
		case addAccount
	}

	fileprivate var accounts: Array<Account>

	required init() {
		self.accounts = []
		super.init(nibName: nil, bundle: nil)
		navigationItem.title = "Accounts"
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
		accounts = AccountsService.accounts()
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch Section(rawValue: section)! {
		case .accounts:
			return accounts.count
		case .addAccount:
			return 1
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch Section(rawValue: (indexPath as NSIndexPath).section)! {
		case .accounts:
			let account = accounts[(indexPath as NSIndexPath).row]
			let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier, for: indexPath)

			cell.textLabel?.text = account.name

			if let currentAccount = AccountsService.account {
				if account == currentAccount {
					cell.accessoryType = .checkmark
				} else {
					cell.accessoryType = .none
				}
			}

			return cell
		case .addAccount:
			let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier, for: indexPath)

			cell.textLabel?.text = "Add account"
			cell.accessoryType = .none

			return cell
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch Section(rawValue: (indexPath as NSIndexPath).section)! {
		case .accounts:
			let account = accounts[(indexPath as NSIndexPath).row]
			AccountsService.loginToAccount(account) { account in
				let alertController = UIAlertController(title: "Switch Account?", message: "Are you sure you want to switch to \(account.name)", preferredStyle: .actionSheet)
				let action = UIAlertAction(title: "Yes", style: .destructive) { _ in
					let notification = Notification(name: Notification.Name(rawValue: AccountDidChangeNotification), object: nil)
					NotificationCenter.default.post(notification)
				}
				let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

				alertController.addAction(action)
				alertController.addAction(cancelAction)

				self.present(alertController, animated: true, completion: nil)
			}
		case .addAccount:
			AccountsService.authenticateNewAccount(fromViewController: self) { _ in
				self.accounts = AccountsService.accounts()
				self.tableView.reloadData()
			}
		}
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return Section(rawValue: (indexPath as NSIndexPath).section) == .accounts
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		guard Section(rawValue: (indexPath as NSIndexPath).section) == .accounts else {
			return
		}

		let account = accounts[(indexPath as NSIndexPath).row]
		let alertController = UIAlertController(title: "Delete Account?", message: "Are you sure youw ant to delete \(account.name)", preferredStyle: .actionSheet)
		let deleteAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
			AccountsService.deleteAccount(account, fromViewController: self) { changedAccount in
				if changedAccount {
					let notification = Notification(name: Notification.Name(rawValue: AccountDidChangeNotification), object: nil)
					NotificationCenter.default.post(notification)
				} else {
					self.accounts = AccountsService.accounts()
					self.tableView.reloadData()
				}
			}
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

		alertController.addAction(deleteAction)
		alertController.addAction(cancelAction)

		present(alertController, animated: true, completion: nil)
	}
}
