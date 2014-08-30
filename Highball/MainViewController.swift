//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

class MainViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate {

    let postHeaderViewIdentifier = "postHeaderViewIdentifier"
    let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
    let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"

    var postsWebViewCache: Dictionary<UIWebView, Int>!
    var webViewHeightCache: Dictionary<Int, CGFloat>!
    var posts: Array<Post>! {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.postsWebViewCache = Dictionary<UIWebView, Int>()
        self.webViewHeightCache = Dictionary<Int, CGFloat>()

        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostHeaderView.classForCoder(), forHeaderFooterViewReuseIdentifier: postHeaderViewIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let oauthToken = TMAPIClient.sharedInstance().OAuthToken {
            TMAPIClient.sharedInstance().dashboard([:]) { (response: AnyObject!, error: NSError!) -> Void in
                if let e = error {
                    println(e)
                    return
                }
                let json = JSONValue(response)
                let posts = json["posts"].array!.map { (post) -> (Post) in
                    return Post(json: post)
                }.filter { (post) -> (Bool) in
                    return post.type == "photo" || post.type == "text"
                }

                for post in posts {
                    if let content = post.body() as NSString? {
                        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                        let htmlString = content.htmlStringWithTumblrStyle(self.view.frame.width)

                        webView.delegate = self
                        webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                        self.postsWebViewCache[webView] = post.id
                    }
                    
                    println(post.json)
                }

                self.posts = posts
            }
        } else {
            TMAPIClient.sharedInstance().authenticate("highballtumblr") { (error: NSError!) -> Void in
                if error == nil {
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthToken, forKey: "HighballOAuthToken")
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthTokenSecret, forKey: "HighballOAuthTokenSecret")
                }
            }
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        if let posts = self.posts {
            var webViewsFinishedLoading = true
            for post in posts {
                if let content = post.body() {
                    if let height = self.webViewHeightCache[post.id] {
                        
                    } else {
                        webViewsFinishedLoading = false
                    }
                }
            }
            if !webViewsFinishedLoading {
                return 0
            }
            return posts.count
        }
        return 0
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let post = self.posts[section]
        let postPhotos = post.photos()
        if postPhotos.count == 1 {
            return 2
        }

        return post.layoutRows().count + 1
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let post = posts[indexPath.section]
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            cell.contentWidth = tableView.frame.size.width
            cell.content = post.body()
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier(photosetRowTableViewCellIdentifier) as PhotosetRowTableViewCell!
        let postPhotos = post.photos()
        if postPhotos.count == 1 {
            cell.images = postPhotos
        } else {
            let photosetLayoutRows = post.layoutRows()
            var photosIndexStart = 0
            for photosetLayoutRow in photosetLayoutRows[0..<indexPath.row] {
                photosIndexStart += photosetLayoutRow
            }
            let photosetLayoutRow = photosetLayoutRows[indexPath.row]

            cell.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
        }
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView!, viewForHeaderInSection section: Int) -> UIView! {
        let post = posts[section]
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(postHeaderViewIdentifier) as PostHeaderView

        view.post = post

        return view
    }

    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let post = posts[indexPath.section]
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            if let height = self.webViewHeightCache[post.id] {
                return height
            }
            return 0
        }

        let postPhotos = post.photos()
        var images: Array<PostPhoto>!

        if postPhotos.count == 1 {
            images = postPhotos
        } else {
            let photosetLayoutRows = post.layoutRows()
            var photosIndexStart = 0
            for photosetLayoutRow in photosetLayoutRows[0..<indexPath.row] {
                photosIndexStart += photosetLayoutRow
            }
            let photosetLayoutRow = photosetLayoutRows[indexPath.row]
            
            images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
        }

        let imageCount = images.count
        let imageWidth = tableView.frame.size.width / CGFloat(images.count)
        let minHeight = images.map { (image: PostPhoto) -> CGFloat in
            let scale = image.height() / image.width()
            return imageWidth * scale
        }.reduce(CGFloat.max, combine: { min($0, $1) })

        return minHeight
    }

    // MARK: UIWebViewDelegate

    func webViewDidFinishLoad(webView: UIWebView!) {
        if let postId = self.postsWebViewCache[webView] {
            self.webViewHeightCache[postId] = webView.documentHeight()
            self.postsWebViewCache[webView] = nil
            self.tableView?.reloadData()
        }
    }
}

public extension UIWebView {
    func documentHeight() -> (CGFloat) {
        return CGFloat(self.stringByEvaluatingJavaScriptFromString("var body = document.body, html = document.documentElement;Math.max( body.scrollHeight, body.offsetHeight,html.clientHeight, html.scrollHeight, html.offsetHeight );").toInt()!)
    }
}
