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
        if let postsJSON = json["posts"].array {
            return postsJSON.map { (post) -> (Post) in
                return Post(json: post)
            }
        }
        return []
    }

    override func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
    }

    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }

    func applicationWillResignActive(notification: NSNotification) {
        self.bookmark()
    }

    func bookmark() {
        guard
            let indexPaths = tableView.indexPathsForVisibleRows,
            let firstIndexPath = indexPaths.first,
            let account = AccountsService.account
        else {
            return
        }

        let post = self.posts[firstIndexPath.section]
        var bookmarks: [[String: AnyObject]] = NSUserDefaults.standardUserDefaults().arrayForKey("HIBookmarks:\(account.blog.url)") as? [[String: AnyObject]] ?? []

        bookmarks.insert(["date": NSDate(), "id": post.id], atIndex: 0)

        if bookmarks.count > 20 {
            bookmarks = [[String: AnyObject]](bookmarks.prefix(20))
        }

        NSUserDefaults.standardUserDefaults().setObject(bookmarks, forKey: "HIBookmarks:\(account.blog.url)")
    }

    func bookmarks(sender: UIButton, event: UIEvent) {
        if let _ = self.topID {
            let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: .Default) { action  in
                self.navigationItem.rightBarButtonItem = nil
                self.topID = nil
                self.posts = []
                self.heightCache.removeAll()
                self.tableView.reloadData()
                self.loadTop()
            })
            alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    func gotoBookmark(id: Int) {
        let upArrow = FAKIonIcons.iosArrowUpIconWithSize(30);
        let upArrowImage = upArrow.imageWithSize(CGSize(width: 30, height: 30))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: upArrowImage,
            style: .Plain,
            target: self,
            action: Selector("bookmarks:event:")
        )

        topID = id
        posts = []
        heightCache.removeAll()
        tableView.reloadData()
        loadTop()
    }
}
