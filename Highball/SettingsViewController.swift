//
//  SettingsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/8/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import PINCache
import PINRemoteImage
import UIKit
import VENTouchLock

class SettingsViewController: UITableViewController {
	fileprivate enum SettingsSection: Int {
		case accounts
		case passcode
		case cache
	}
	fileprivate enum PasscodeRow: Int {
		case set
		case clearPasscode
		case useTouch
	}

	init() {
		super.init(style: .grouped)
		navigationItem.title = "Settings"
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
	}

	override func viewDidAppear(_ animated: Bool) {
		guard let selectedInexPath = tableView.indexPathForSelectedRow else {
			return
		}

		tableView.deselectRow(at: selectedInexPath, animated: animated)
	}

	func done(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch SettingsSection(rawValue: section)! {
		case .accounts:
			return 1
		case .passcode:
			return VENTouchLock.canUseTouchID() ? 3 : 2
		case .cache:
			return 1
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.cellIdentifier, for: indexPath)

		switch SettingsSection(rawValue: (indexPath as NSIndexPath).section)! {
		case .accounts:
			cell.textLabel?.text = "Accounts"
			cell.accessoryType = .disclosureIndicator
		case .passcode:
			switch PasscodeRow(rawValue: (indexPath as NSIndexPath).row)! {
			case .set:
				if VENTouchLock.sharedInstance().isPasscodeSet() {
					cell.textLabel?.text = "Update Passcode"
				} else {
					cell.textLabel?.text = "Set Passcode"
				}
				cell.accessoryType = .disclosureIndicator
			case .clearPasscode:
				cell.textLabel?.text = "Clear Passcode"
			case .useTouch:
				cell.textLabel?.text = "Use Touch ID"
				if VENTouchLock.shouldUseTouchID() {
					cell.accessoryType = .checkmark
				} else {
					cell.accessoryType = .none
				}
			}
		case .cache:
			cell.textLabel?.text = "Clear Cache"
			cell.accessoryType = .none
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)

		switch SettingsSection(rawValue: (indexPath as NSIndexPath).section)! {
		case .accounts:
			navigationController?.pushViewController(AccountsViewController(), animated: true)
		case .passcode:
			switch PasscodeRow(rawValue: (indexPath as NSIndexPath).row)! {
			case .set:
				let viewController = VENTouchLockCreatePasscodeViewController()
				if let navigationController = self.navigationController {
					viewController.willFinishWithResult = { finished in
						navigationController.popViewController(animated: true)
					}
					navigationController.pushViewController(viewController, animated: true)
				}
			case .clearPasscode:
				if VENTouchLock.sharedInstance().isPasscodeSet() {
					VENTouchLock.sharedInstance().deletePasscode()
				}
				tableView.reloadData()
			case .useTouch:
				if VENTouchLock.shouldUseTouchID() {
					VENTouchLock.setShouldUseTouchID(false)
				} else {
					VENTouchLock.setShouldUseTouchID(true)
				}
				tableView.reloadData()
			}
		case .cache:
			let alertController = UIAlertController(title: "Are you sure?", message: "Are you sure that you want to clear your cache?", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "Yes", style: .destructive) { action in
				PINRemoteImageManager.shared().cache.diskCache.removeAllObjects(nil)
				PINCache.shared().diskCache.removeAllObjects(nil)
			})
			alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
			present(alertController, animated: true, completion: nil)
		}
	}
}
