//
//  AccountsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/16/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

// swiftlint:disable variable_name
public let AccountDidChangeNotification = "AccountDidChangeNotification"
// swiftlint:enable variable_name

class AccountsViewController: UITableViewController {
    private enum Section: Int {
        case Accounts
        case AddAccount
    }

    private var accounts: Array<Account>

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

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
        accounts = AccountsService.accounts()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Accounts:
            return accounts.count
        case .AddAccount:
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .Accounts:
            let account = accounts[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)

            cell.textLabel?.text = account.blog.name

            if let currentAccount = AccountsService.account {
                if account == currentAccount {
                    cell.accessoryType = .Checkmark
                } else {
                    cell.accessoryType = .None
                }
            }

            return cell
        case .AddAccount:
            let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier)!

            cell.textLabel?.text = "Add account"
            cell.accessoryType = .None

            return cell
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .Accounts:
            let account = accounts[indexPath.row]
            AccountsService.loginToAccount(account) {
                let alertController = UIAlertController(title: "Switch Account?", message: "Are you sure you want to switch to \(account.blog.name)", preferredStyle: .ActionSheet)
                let action = UIAlertAction(title: "Yes", style: .Destructive) { _ in
                    let notification = NSNotification(name: AccountDidChangeNotification, object: nil)
                    NSNotificationCenter.defaultCenter().postNotification(notification)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

                alertController.addAction(action)
                alertController.addAction(cancelAction)

                self.presentViewController(alertController, animated: true, completion: nil)
            }
        case .AddAccount:
            AccountsService.authenticateNewAccount(fromViewController: self) { (account) -> () in
                self.accounts = AccountsService.accounts()
                self.tableView.reloadData()
            }
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return Section(rawValue: indexPath.section) == .Accounts
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard Section(rawValue: indexPath.section) == .Accounts else {
            return
        }

        let account = accounts[indexPath.row]
        AccountsService.deleteAccount(account, fromViewController: self) {
            self.accounts = AccountsService.accounts()
            self.tableView.reloadData()
        }
    }
}
