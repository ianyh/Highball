//
//  HistoryViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/28/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

class HistoryViewController: UITableViewController {
    private var bookmarks: [[String: AnyObject]]?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        bookmarks = NSUserDefaults.standardUserDefaults().arrayForKey("HIBookmarks:\(AccountsService.account.blog.url)") as? [[String: AnyObject]]
        bookmarks = bookmarks?.sort { ($0["date"] as! NSDate).compare($1["date"] as! NSDate) == .OrderedDescending }

        tableView.reloadData()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let bookmark = bookmarks![indexPath.row]

        cell.accessoryType = .DisclosureIndicator
        cell.textLabel?.text = "\(bookmark["date"] as! NSDate)"

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let bookmark = bookmarks![indexPath.row]

        print(bookmark)
    }
}
