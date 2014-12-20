//
//  LikesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class LikesViewController: PostsViewController {
    var currentOffset: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Likes"
    }

    override func loadTop() {
        if self.loadingTop! {
            return
        }
        
        self.loadingTop = true
        
        TMAPIClient.sharedInstance().likes([:]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                println(e)
            } else {
                let json = JSON(response)
                let posts = json["liked_posts"].array!.map { (post) -> (Post) in
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
            }

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
                TMAPIClient.sharedInstance().likes(["offset" : self.currentOffset! + 20]) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        println(e)
                    } else {
                        let json = JSON(response)
                        let posts = json["liked_posts"].array!.map { (post) -> (Post) in
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
                    }

                    self.loadingBottom = false
                }
            }
        }
    }
    
    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }
}
