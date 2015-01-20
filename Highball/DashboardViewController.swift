//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class DashboardViewController: PostsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.Bookmarks,
            target: self,
            action: Selector("bookmarks:event:")
        )

        self.navigationItem.title = AccountsService.account.blog.name
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

    func bookmarks(sender: UIButton, event: UIEvent) {
        if let touches = event.allTouches() {
            if let touch = touches.anyObject() as? UITouch {
                if let navigationController = self.navigationController {
                    let viewController = BookmarksViewController()

                    viewController.startingPoint = touch.locationInView(self.view)
                    viewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                    viewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    viewController.view.bounds = navigationController.view.bounds

                    viewController.completion = { bookmarksOption in
                        if let option = bookmarksOption {
                            switch(option) {
                            case .Bookmark:
                                if let indexPaths = self.tableView.indexPathsForVisibleRows() {
                                    if let firstIndexPath = indexPaths.first as? NSIndexPath {
                                        let post = self.posts[firstIndexPath.section]
                                        NSUserDefaults.standardUserDefaults().setObject(post.timestamp, forKey: "HITimestampBookmark")
                                    }
                                }
                            case .Goto:
                                self.gotoBookmark()
                            case .Top:
                                self.topOffset = 0
                                self.loadTop()
                            }
                        }
                        navigationController.dismissViewControllerAnimated(true, completion: nil)
                    }

                    navigationController.presentViewController(viewController, animated: true, completion: nil)
                }
            }
        }
    }

    func gotoBookmark() {
        if let bookmarkTimestamp = NSUserDefaults.standardUserDefaults().objectForKey("HITimestampBookmark") as? Int {
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
