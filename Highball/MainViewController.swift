//
//  MainViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

enum AnswerRow: Int {
    case Question
    case Answer
}

class MainViewController: UITableViewController, UIWebViewDelegate {

    let postHeaderViewIdentifier = "postHeaderViewIdentifier"
    let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
    let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
    let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"

    var postsWebViewCache: Dictionary<Int, UIWebView>!
    var webViewHeightCache: Dictionary<Int, CGFloat>!
    var posts: Array<Post>! {
        didSet {
            self.reloadTable()
        }
    }

    var currentOffset: Int?
    var loadingTop: Bool?
    var loadingBottom: Bool?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadingTop = false
        self.loadingBottom = false

        self.postsWebViewCache = Dictionary<Int, UIWebView>()
        self.webViewHeightCache = Dictionary<Int, CGFloat>()

        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostQuestionTableViewCell.classForCoder(), forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        self.tableView.registerClass(PostHeaderView.classForCoder(), forHeaderFooterViewReuseIdentifier: postHeaderViewIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let oauthToken = TMAPIClient.sharedInstance().OAuthToken {
            self.loadTop()
        } else {
            TMAPIClient.sharedInstance().authenticate("highballtumblr") { (error: NSError!) -> Void in
                if error == nil {
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthToken, forKey: "HighballOAuthToken")
                    NSUserDefaults.standardUserDefaults().setObject(TMAPIClient.sharedInstance().OAuthTokenSecret, forKey: "HighballOAuthTokenSecret")
                }
            }
        }
    }

    func loadTop() {
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
                if let content = post.body() as NSString? {
                    let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                    let htmlString = content.htmlStringWithTumblrStyle(self.view.frame.width)

                    webView.delegate = self
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                    self.postsWebViewCache[post.id] = webView
                }
                    
                println(post.json)
            }

            self.posts = posts
            self.currentOffset = 0

            self.loadingTop = false
        }
    }

    func loadMore() {
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
                    }.filter { (post) -> (Bool) in
                        return post.type == "photo" || post.type == "text"
                    }
                    
                    for post in posts {
                        if let content = post.body() as NSString? {
                            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                            let htmlString = content.htmlStringWithTumblrStyle(self.view.frame.width)
                            
                            webView.delegate = self
                            webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                            
                            self.postsWebViewCache[post.id] = webView
                        }
                        
                        println(post.json)
                    }

                    self.posts.extend(posts)
                    self.currentOffset! += 20
                    self.reloadTable()

                    self.loadingBottom = false
                }
            }
        }
    }

    func reloadTable() {
        if let posts = self.posts {
            var webViewsFinishedLoading = true
            for post in posts {
                if let content = post.body() {
                    if let height = self.webViewHeightCache[post.id] {} else {
                        return
                    }
                }
            }
        }

        self.tableView?.reloadData()
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        if let posts = self.posts {
            return posts.count
        }
        return 0
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let post = self.posts[section]
        switch post.type {
        case "photo":
            let postPhotos = post.photos()
            if postPhotos.count == 1 {
                return 2
            }

            return post.layoutRows().count + 1
        case "text":
            return 1
        case "answer":
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let post = posts[indexPath.section]
        switch post.type {
        case "photo":
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
        case "text":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            cell.contentWidth = tableView.frame.size.width
            cell.content = post.body()
            return cell
        case "answer":
            switch AnswerRow.fromRaw(indexPath.row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(postQuestionTableViewCellIdentifier) as PostQuestionTableViewCell!
                cell.post = post
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.contentWidth = tableView.frame.size.width
                cell.content = post.body()
                return cell
            }
        default:
            return nil
        }
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
        switch post.type {
        case "photo":
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
        case "text":
            if let height = self.webViewHeightCache[post.id] {
                return height
            }
            return 0
        case "answer":
            switch AnswerRow.fromRaw(indexPath.row)! {
            case .Question:
                return PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.size.width)
            case .Answer:
                if let height = self.webViewHeightCache[post.id] {
                    return height
                }
                return 0
            }
        default:
            return 0
        }
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView!) {
        let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

        if distanceFromBottom < 2000 {
            self.loadMore()
        }
    }

    // MARK: UIWebViewDelegate

    func webViewDidFinishLoad(webView: UIWebView!) {
        if let postId = self.postsWebViewCache.keyForObject(webView, isEqual: ==) {
            self.webViewHeightCache[postId] = webView.documentHeight()
            self.postsWebViewCache[postId] = nil
            self.reloadTable()
        }
    }
}

public extension UIWebView {
    func documentHeight() -> (CGFloat) {
        return CGFloat(self.stringByEvaluatingJavaScriptFromString("var body = document.body, html = document.documentElement;Math.max( body.scrollHeight, body.offsetHeight,html.clientHeight, html.scrollHeight, html.offsetHeight );").toInt()!)
    }
}

public extension Dictionary {
    func keyForObject(object: Value!, isEqual: (Value!, Value!) -> (Bool)) -> (Key?) {
        for key in self.keys {
            if isEqual(object, self[key] as Value!) {
                return key
            }
        }
        return nil
    }
}
