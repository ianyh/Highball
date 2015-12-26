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
    private let cellIdentifier = "cellIdentifier"

    private var tableView: UITableView!
    private var accounts: Array<Account>!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.accounts = AccountsService.accounts()

        self.view.backgroundColor = UIColor.whiteColor()

        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.allowsSelection = true
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)

        self.view.addSubview(self.tableView)

        constrain(self.tableView, self.view) { tableView, view in
            tableView.edges == view.edges; return
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let account = self.accounts[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!

        cell.textLabel?.text = account.blog.name

        if let currentAccount = AccountsService.account {
            if account == currentAccount {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let account = self.accounts[indexPath.row]
        AccountsService.loginToAccount(account) {
            if let navigationController = self.presentingViewController as? UINavigationController {
                navigationController.viewControllers = [DashboardViewController()]
            }
            self.tableView.reloadData()
            self.showPasscodeAnimated(true)
        }
    }
}
