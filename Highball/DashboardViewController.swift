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

    var currentOffset: Int?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func login() {
        if self.loggingIn {
            return
        }

        self.loggingIn = true

        if let oauthToken = TMAPIClient.sharedInstance().OAuthToken {
            TMAPIClient.sharedInstance().userInfo { response, error in
                if let e = error {
                    println(e)
                    return
                }

                let json = JSONValue(response)
                println(json)

                self.blogs = json["user"]["blogs"].array!.map({ Blog(json: $0) })
                self.primaryBlog = self.blogs.filter({ $0.primary }).first

                self.loadTop()
            }
        } else {
            TMAPIClient.sharedInstance().authenticate("highballtumblr") { (error: NSError!) -> Void in
                self.loggingIn = false

                if error == nil {
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthToken, forKey: "HighballOAuthToken")
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthTokenSecret, forKey: "HighballOAuthTokenSecret")

                    self.login()
                }
            }
        }
    }

    func applicationDidBecomeActive(notification: NSNotification!) {
        self.login()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        TMAPIClient.sharedInstance().dashboard([:]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                println(e)
                return
            }
            let json = JSONValue(response)
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
            self.currentOffset = 0

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
                TMAPIClient.sharedInstance().dashboard(["offset" : self.currentOffset! + 20]) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        println(e)
                        return
                    }
                    let json = JSONValue(response)
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
                    }

                    self.posts.extend(posts)
                    self.currentOffset! += 20
                    self.reloadTable()

                    self.loadingBottom = false
                }
            }
        }
    }

    override func reblogBlogName() -> (String) {
        return self.primaryBlog.name
    }
}
