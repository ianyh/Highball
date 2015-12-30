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

class SettingsViewController : UITableViewController {
    private enum SettingsSection: Int {
        case Accounts
        case Passcode
        case Cache
    }
    private enum PasscodeRow: Int {
        case Set
        case ClearPasscode
        case UseTouch
    }

    init() {
        super.init(style: .Grouped)
        navigationItem.title = "Settings"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
    }

    override func viewDidAppear(animated: Bool) {
        guard let selectedInexPath = tableView.indexPathForSelectedRow else {
            return
        }

        tableView.deselectRowAtIndexPath(selectedInexPath, animated: animated)
    }

    func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SettingsSection(rawValue: section)! {
        case .Accounts:
            return 1
        case .Passcode:
            return VENTouchLock.canUseTouchID() ? 3 : 2
        case .Cache:
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)

        switch SettingsSection(rawValue: indexPath.section)! {
        case .Accounts:
            cell.textLabel?.text = "Accounts"
            cell.accessoryType = .DisclosureIndicator
        case .Passcode:
            switch PasscodeRow(rawValue: indexPath.row)! {
            case .Set:
                if VENTouchLock.sharedInstance().isPasscodeSet() {
                    cell.textLabel?.text = "Update Passcode"
                } else {
                    cell.textLabel?.text = "Set Passcode"
                }
                cell.accessoryType = .DisclosureIndicator
            case .ClearPasscode:
                cell.textLabel?.text = "Clear Passcode"
            case .UseTouch:
                cell.textLabel?.text = "Use Touch ID"
                if VENTouchLock.shouldUseTouchID() {
                    cell.accessoryType = .Checkmark
                } else {
                    cell.accessoryType = .None
                }
            }
        case .Cache:
            cell.textLabel?.text = "Clear Cache"
            cell.accessoryType = .None
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        switch SettingsSection(rawValue: indexPath.section)! {
        case .Accounts:
            navigationController?.pushViewController(AccountsViewController(), animated: true)
        case .Passcode:
            switch PasscodeRow(rawValue: indexPath.row)! {
            case .Set:
                let viewController = VENTouchLockCreatePasscodeViewController()
                if let navigationController = self.navigationController {
                    viewController.willFinishWithResult = { finished in
                        navigationController.popViewControllerAnimated(true)
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
        case .Cache:
            let alertController = UIAlertController(title: "Are you sure?", message: "Are you sure that you want to clear your cache?", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: .Destructive) { action in
                PINRemoteImageManager.sharedImageManager().cache.diskCache.removeAllObjects(nil)
                PINCache.sharedCache().diskCache.removeAllObjects(nil)
            })
            alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
