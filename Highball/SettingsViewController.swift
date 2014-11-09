//
//  SettingsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/8/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
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
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(settingsCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        cell.textLabel.text = "Passcode"
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }
}
