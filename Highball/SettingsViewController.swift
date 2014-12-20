//
//  SettingsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/8/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    private enum SettingsSection: Int {
        case Accounts
        case Passcode
    }
    private enum PasscodeRow: Int {
        case Set
        case ClearPasscode
        case UseTouch
    }
    let settingsCellIdentifier = "settingsCellIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("done:"))

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: settingsCellIdentifier)
    }

    override func viewDidAppear(animated: Bool) {
        if let selectedInexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedInexPath, animated: animated)
        }
    }

    func done(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SettingsSection(rawValue: section)! {
        case .Accounts:
            return 1
        case .Passcode:
            if VENTouchLock.canUseTouchID() {
                return 3
            }
            return 2
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(settingsCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        switch SettingsSection(rawValue: indexPath.section)! {
        case .Accounts:
            cell.textLabel?.text = "Accounts"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        case .Passcode:
            switch PasscodeRow(rawValue: indexPath.row)! {
            case .Set:
                if VENTouchLock.sharedInstance().isPasscodeSet() {
                    cell.textLabel?.text = "Update Passcode"
                } else {
                    cell.textLabel?.text = "Set Passcode"
                }
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            case .ClearPasscode:
                cell.textLabel?.text = "Clear Passcode"
            case .UseTouch:
                cell.textLabel?.text = "Use Touch ID"
                if VENTouchLock.shouldUseTouchID() {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        switch SettingsSection(rawValue: indexPath.section)! {
        case .Accounts:
            if let navigationController = self.navigationController {
                navigationController.pushViewController(AccountsViewController(), animated: true)
            }
        case .Passcode:
            switch PasscodeRow(rawValue: indexPath.row)! {
            case .Set:
                let viewController = VENTouchLockCreatePasscodeViewController()
                if let navigationController = self.navigationController {
                    viewController.willFinishWithResult = { finished in
                        navigationController.popViewControllerAnimated(true); return
                    }
                    navigationController.pushViewController(viewController, animated: true)
                }
            case .ClearPasscode:
                if VENTouchLock.sharedInstance().isPasscodeSet() {
                    VENTouchLock.sharedInstance().deletePasscode()
                }
                tableView.reloadData()
            case .UseTouch:
                if VENTouchLock.shouldUseTouchID() {
                    VENTouchLock.setShouldUseTouchID(false)
                } else {
                    VENTouchLock.setShouldUseTouchID(true)
                }
                tableView.reloadData()
            }
        }
    }
}
