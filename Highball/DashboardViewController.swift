//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import SwiftyJSON

class DashboardViewController: PostsViewController {
    required override init() {
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

        let downArrow =  FAKIonIcons.iosArrowDownIconWithSize(30);
        let downArrowImage = downArrow.imageWithSize(CGSize(width: 30, height: 30))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: downArrowImage,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("bookmarks:event:")
        )

        self.navigationItem.title = "Dashboard"
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
        if let indexPaths = self.collectionView?.indexPathsForVisibleItems() {
            if let firstIndexPath = indexPaths.first as? NSIndexPath {
                let post = self.posts[firstIndexPath.row]
                if let account = AccountsService.account {} else {
                    return
                }
                NSUserDefaults.standardUserDefaults().setObject(post.id, forKey: "HIBookmarkID:\(AccountsService.account.blog.url)")
            }
        }
    }

    func bookmarks(sender: UIButton, event: UIEvent) {
        if let topID = self.topID {
            let alertController = UIAlertController(title: "", message: "Go to top of your feed?", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action -> Void in
                self.topID = nil
                self.loadTop()
                let downArrow = FAKIonIcons.iosArrowDownIconWithSize(30);
                let downArrowImage = downArrow.imageWithSize(CGSize(width: 30, height: 30))
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: downArrowImage,
                    style: UIBarButtonItemStyle.Plain,
                    target: self,
                    action: Selector("bookmarks:event:")
                )
            }))
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "", message: "Go to your last dashboard position?", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action -> Void in
                self.gotoBookmark()
                let upArrow = FAKIonIcons.iosArrowUpIconWithSize(30);
                let upArrowImage = upArrow.imageWithSize(CGSize(width: 30, height: 30))
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: upArrowImage,
                    style: UIBarButtonItemStyle.Plain,
                    target: self,
                    action: Selector("bookmarks:event:")
                )
            }))
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    func gotoBookmark() {
        if let bookmarkID = NSUserDefaults.standardUserDefaults().objectForKey("HIBookmarkID:\(AccountsService.account.blog.url)") as? Int {
            self.topID = bookmarkID
            self.posts = []
            self.heightCache.removeAll()
            self.loadTop()
        }
    }
}
