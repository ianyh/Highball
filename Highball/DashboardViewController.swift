//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class DashboardViewController: PostsViewController {
    required init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("applicationWillResignActive:"),
            name: UIApplicationWillResignActiveNotification,
            object: nil
        )
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationWillResignActiveNotification,
            object: nil
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let downArrow = FAKFontAwesome.angleDownIconWithSize(30)
        let downArrowImage = downArrow.imageWithSize(CGSize(width: 30, height: 30))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: downArrowImage,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("bookmarks:event:")
        )

        self.navigationItem.title = AccountsService.account.blog.name
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

    override func requestPosts(parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
    }

    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }

    func applicationWillResignActive(notification: NSNotification) {
        self.bookmark()
    }

    func bookmark() {
        if let indexPaths = self.tableView.indexPathsForVisibleRows() {
            if let firstIndexPath = indexPaths.first as? NSIndexPath {
                let post = self.posts[firstIndexPath.section]
                NSUserDefaults.standardUserDefaults().setObject(post.timestamp, forKey: "HITimestampBookmark:\(AccountsService.account.blog.url)")
            }
        }
    }

    func bookmarks(sender: UIButton, event: UIEvent) {
        if self.topOffset > 0 {
            let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action -> Void in
                self.topOffset = 0
                self.loadTop()
            }))
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "", message: "Go to your last dashboard position?", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action -> Void in
                self.gotoBookmark()
            }))
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    func gotoBookmark() {
        if let bookmarkTimestamp = NSUserDefaults.standardUserDefaults().objectForKey("HITimestampBookmark:\(AccountsService.account.blog.url)") as? Int {
            self.findMax(bookmarkTimestamp, offset: 0)
        }
    }

    func findMax(bookmarkTimestamp: Int, offset: Int) {
        TMAPIClient.sharedInstance().dashboard(["offset" : offset, "limit" : 1]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                return
            }
            let json = JSON(response)
            let posts = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }
            let lastPost = posts.last!
            if lastPost.timestamp > bookmarkTimestamp {
                if offset == 0 {
                    self.findMax(bookmarkTimestamp, offset: 20)
                } else {
                    self.findMax(bookmarkTimestamp, offset: offset * 2)
                }
            } else {
                if offset == 20 {
                    self.findOffset(bookmarkTimestamp, startOffset: 0, endOffset: 20)
                } else {
                    self.findOffset(bookmarkTimestamp, startOffset: offset / 2, endOffset: offset)
                }
            }
        }
    }

    func findOffset(bookmarkTimestamp: Int, startOffset: Int, endOffset: Int) {
        let offset = (startOffset + endOffset) / 2
        TMAPIClient.sharedInstance().dashboard(["offset" : offset, "limit" : 1]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                return
            }
            let json = JSON(response)
            let post = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }.first!
            if post.timestamp > bookmarkTimestamp {
                self.findOffset(bookmarkTimestamp, startOffset: offset, endOffset: endOffset)
            } else if post.timestamp < bookmarkTimestamp {
                self.findOffset(bookmarkTimestamp, startOffset: startOffset, endOffset: offset)
            } else {
                self.topOffset = offset + 20
                self.loadTop()
            }
        }
    }
}
