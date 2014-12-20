//
//  DashboardViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class DashboardViewController: PostsViewController {
    var blogs: Array<Blog>!
    var primaryBlog: Blog! {
        didSet {
            self.navigationItem.title = self.primaryBlog.name
        }
    }

    var topOffset = 0
    var bottomOffset = 0

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func login() {
//        if self.loggingIn {
//            return
//        }
//
//        self.loggingIn = true
//
//        if let oauthToken = TMAPIClient.sharedInstance().OAuthToken {
//            TMAPIClient.sharedInstance().userInfo { response, error in
//                if let e = error {
//                    println(e)
//                    return
//                }
//
//                let json = JSON(response)
//                println(json)
//
//                self.blogs = json["user"]["blogs"].array!//.map({ Blog(json: $0) })
//                self.primaryBlog = self.blogs.filter({ $0.primary }).first
//
//                self.loadTop()
//            }
//        } else {
//            TMAPIClient.sharedInstance().authenticate("highballtumblr") { (error: NSError!) -> Void in
//                self.loggingIn = false
//
//                if error == nil {
//                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthToken, forKey: "HighballOAuthToken")
//                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthTokenSecret, forKey: "HighballOAuthTokenSecret")
//
//                    self.login()
//                }
//            }
//        }
    }

    func applicationDidBecomeActive(notification: NSNotification!) {
        self.login()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.Bookmarks,
            target: self,
            action: Selector("bookmarks:event:")
        )

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("applicationDidBecomeActive:"),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.login()
    }

    override func loadTop() {
        if self.loadingTop! {
            return
        }

        self.loadingTop = true

        if self.topOffset >= 20 {
            self.topOffset -= 20
        } else if self.topOffset > 0 {
            self.topOffset = 0
        }

        self.bottomOffset = 0

        TMAPIClient.sharedInstance().dashboard([ "offset" : self.topOffset ]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                println(e)
                return
            }
            let json = JSON(response)
//            println(json)
            let posts = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }

            for post in posts {
                if let content = post.htmlBodyWithWidth(self.tableView.frame.size.width) {
                    let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
                    let htmlString = content

                    webView.delegate = self
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                    self.bodyWebViewCache[post.id] = webView
                }

                if let content = post.htmlSecondaryBodyWithWidth(self.tableView.frame.size.width) {
                    let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
                    let htmlString = content

                    webView.delegate = self
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                    self.secondaryBodyWebViewCache[post.id] = webView
                }
            }

            self.posts = posts
            self.loadingTop = false
        }
    }

    override func loadMore() {
        if self.loadingTop! || self.loadingBottom! {
            return
        }

        if let posts = self.posts {
            if let lastPost = posts.last {
                self.loadingBottom = true
                TMAPIClient.sharedInstance().dashboard(["offset" : self.topOffset + self.bottomOffset + 20]) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        println(e)
                        return
                    }
                    let json = JSON(response)
                    let posts = json["posts"].array!.map { (post) -> (Post) in
                        return Post(json: post)
                    }
                    
                    for post in posts {
                        if let content = post.htmlBodyWithWidth(self.tableView.frame.size.width) {
                            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
                            let htmlString = content
                            
                            webView.delegate = self
                            webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                            
                            self.bodyWebViewCache[post.id] = webView
                        }

                        if let content = post.htmlSecondaryBodyWithWidth(self.tableView.frame.size.width) {
                            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
                            let htmlString = content

                            webView.delegate = self
                            webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))

                            self.secondaryBodyWebViewCache[post.id] = webView
                        }
                    }

                    self.posts.extend(posts)
                    self.bottomOffset += 20
                    self.reloadTable()

                    self.loadingBottom = false
                }
            }
        }
    }

    override func reblogBlogName() -> (String) {
        return self.primaryBlog.name
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
                                    println(indexPaths)
                                    if let firstIndexPath = indexPaths.first as? NSIndexPath {
                                        let post = self.posts[firstIndexPath.section]
                                        NSUserDefaults.standardUserDefaults().setObject(post.id, forKey: "HIPostIDBookmark")
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
        if let bookmarkID = NSUserDefaults.standardUserDefaults().objectForKey("HIPostIDBookmark") as? Int {
            self.findMax(bookmarkID, offset: 0)
        }
    }

    func findMax(bookmarkID: Int, offset: Int) {
        TMAPIClient.sharedInstance().dashboard(["offset" : offset, "limit" : 1]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                return
            }
            let json = JSON(response)
            let posts = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }
            let lastPost = posts.last!
            if lastPost.id > bookmarkID {
                if offset == 0 {
                    self.findMax(bookmarkID, offset: 20)
                } else {
                    self.findMax(bookmarkID, offset: offset * 2)
                }
            } else {
                if offset == 20 {
                    self.findOffset(bookmarkID, startOffset: 0, endOffset: 20)
                } else {
                    self.findOffset(bookmarkID, startOffset: offset / 2, endOffset: offset)
                }
            }
        }
    }

    func findOffset(bookmarkID: Int, startOffset: Int, endOffset: Int) {
        let offset = (startOffset + endOffset) / 2
        TMAPIClient.sharedInstance().dashboard(["offset" : offset, "limit" : 1]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                return
            }
            let json = JSON(response)
            let post = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }.first!
            if post.id > bookmarkID {
                self.findOffset(bookmarkID, startOffset: offset, endOffset: endOffset)
            } else if post.id < bookmarkID {
                self.findOffset(bookmarkID, startOffset: startOffset, endOffset: offset)
            } else {
                self.topOffset = offset + 20
                self.loadTop()
            }
        }
    }
}
