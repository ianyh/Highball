//
//  AccountsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/16/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class AccountsViewController: UITableViewController {
    private enum Section: Int {
        case Accounts
        case AddAccount
    }
    private let cellIdentifier = "cellIdentifier"

    private var accounts: Array<Account>

    required override init() {
        self.accounts = []
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        self.accounts = []
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
        self.accounts = AccountsService.accounts()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Accounts:
            return countElements(self.accounts)
        case .AddAccount:
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .Accounts:
            let account = self.accounts[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!

            cell.textLabel?.text = account.blog.name

            if let currentAccount = AccountsService.account {
                if account == currentAccount {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }

            return cell
        case .AddAccount:
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!

            cell.textLabel?.text = "Add account"

            return cell
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .Accounts:
            let account = self.accounts[indexPath.row]
            AccountsService.loginToAccount(account, completion: { () -> () in
                self.tableView.reloadData()
            })
        case .AddAccount:
            AccountsService.authenticateNewAccount { (account) -> () in
                self.accounts = AccountsService.accounts()
                self.tableView.reloadData()
            }
        }
    }
}
