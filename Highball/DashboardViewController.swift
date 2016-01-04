//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import FontAwesomeKit
import SwiftyJSON
import TMTumblrSDK
import UIKit

class DashboardViewController: PostsViewController {
    override init() {
        super.init()

        navigationItem.title = "Dashboard"

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("applicationWillResignActive:"),
            name: UIApplicationWillResignActiveNotification,
            object: nil
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationWillResignActiveNotification,
            object: nil
        )
    }

    override func viewDidDisappear(animated: Bool) {
        self.bookmark()
    }

    override func postsFromJSON(json: JSON) -> Array<Post> {
        guard let postsJSON = json["posts"].array else {
            return []
        }

        return postsJSON.map { post -> Post in
            return Post(json: post)
        }
    }

    override func requestPosts(postCount: Int, parameters: [String: AnyObject], callback: TMAPICallback) {
        TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
    }

    func applicationWillResignActive(notification: NSNotification) {
        bookmark()
    }

    func bookmark() {
        guard
            let indexPaths = tableView.indexPathsForVisibleRows,
            let firstIndexPath = indexPaths.first,
            let account = AccountsService.account
        else {
            return
        }

        let userDefaults = NSUserDefaults.standardUserDefaults()
        let bookmarksKey = "HIBookmarks:\(account.blog.url)"
        let postIndex = firstIndexPath.section > 0 ? firstIndexPath.section - 1 : firstIndexPath.section
        let post = dataManager.posts[postIndex]
        var bookmarks: [[String: AnyObject]] = userDefaults.arrayForKey(bookmarksKey) as? [[String: AnyObject]] ?? []

        bookmarks.insert(["date": NSDate(), "id": post.id], atIndex: 0)

        if bookmarks.count > 20 {
            bookmarks = [[String: AnyObject]](bookmarks.prefix(20))
        }

        userDefaults.setObject(bookmarks, forKey: bookmarksKey)
    }

    func bookmarks(sender: UIButton, event: UIEvent) {
        guard dataManager.topID != nil else {
            return
        }

        let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .Default) { action  in
            self.navigationItem.rightBarButtonItem = nil
            self.dataManager.topID = nil
            self.dataManager.posts = []
            self.tableViewAdapter?.resetCache()
            self.tableView.reloadData()
            self.dataManager.loadTop(self.tableView.frame.width)
        })
        alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func gotoBookmark(bookmarkID: Int) {
        let upArrow = FAKIonIcons.iosArrowUpIconWithSize(30)
        let upArrowImage = upArrow.imageWithSize(CGSize(width: 30, height: 30))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: upArrowImage,
            style: .Plain,
            target: self,
            action: Selector("bookmarks:event:")
        )

        dataManager.topID = bookmarkID
        dataManager.cursor = bookmarkID
        dataManager.posts = []
        dataManager.loadMore(tableView.frame.width)
        tableViewAdapter?.resetCache()
        tableView.reloadData()
    }
}
