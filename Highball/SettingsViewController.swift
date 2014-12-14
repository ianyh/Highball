//
//  SettingsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/8/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    private enum PasscodeRow: Int {
        case Set
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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if VENTouchLock.canUseTouchID() {
            return 2
        }
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(settingsCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        switch PasscodeRow(rawValue: indexPath.row)! {
        case .Set:
            cell.textLabel?.text = "Passcode"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        case .UseTouch:
            cell.textLabel?.text = "Use Touch ID"
            if VENTouchLock.shouldUseTouchID() {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch PasscodeRow(rawValue: indexPath.row)! {
        case .Set:
            let viewController = VENTouchLockCreatePasscodeViewController()
            if let navigationController = self.navigationController {
                viewController.willFinishWithResult = { finished in
                    navigationController.popViewControllerAnimated(true); return
                }
                navigationController.pushViewController(viewController, animated: true)
            }
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
