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

enum QuoteRow: Int {
    case Quote
    case Source
}

enum LinkRow: Int {
    case Link
    case Description
}

enum VideoRow: Int {
    case Player
    case Caption
}

class MainViewController: UITableViewController, UIWebViewDelegate {

    let postHeaderViewIdentifier = "postHeaderViewIdentifier"
    let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
    let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
    let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"
    let postLinkTableViewCellIdentifier = "postLinkTableViewCellIdentifier"
    let postDialogueEntryTableViewCellIdentifier = "postDialogueEntryTableViewCellIdentifier"

    var bodyWebViewCache: Dictionary<Int, UIWebView>!
    var bodyHeightCache: Dictionary<Int, CGFloat>!
    var secondaryBodyWebViewCache: Dictionary<Int, UIWebView>!
    var secondaryBodyHeightCache: Dictionary<Int, CGFloat>!
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

        self.bodyWebViewCache = Dictionary<Int, UIWebView>()
        self.bodyHeightCache = Dictionary<Int, CGFloat>()
        self.secondaryBodyWebViewCache = Dictionary<Int, UIWebView>()
        self.secondaryBodyHeightCache = Dictionary<Int, CGFloat>()

        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostQuestionTableViewCell.classForCoder(), forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        self.tableView.registerClass(PostLinkTableViewCell.classForCoder(), forCellReuseIdentifier: postLinkTableViewCellIdentifier)
        self.tableView.registerClass(PostDialogueEntryTableViewCell.classForCoder(), forCellReuseIdentifier: postDialogueEntryTableViewCellIdentifier)
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

        TMAPIClient.sharedInstance().dashboard([ "type" : "video" ]) { (response: AnyObject!, error: NSError!) -> Void in
            if let e = error {
                println(e)
                return
            }
            let json = JSONValue(response)
            let posts = json["posts"].array!.map { (post) -> (Post) in
                return Post(json: post)
            }

            for post in posts {
                if let content = post.htmlBodyWithWidth(self.view.frame.size.width) {
                    let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                    let htmlString = content

                    webView.delegate = self
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                    self.bodyWebViewCache[post.id] = webView
                }

                if let content = post.htmlSecondaryBodyWithWidth(self.view.frame.size.width) {
                    let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                    let htmlString = content

                    webView.delegate = self
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
        
                    self.secondaryBodyWebViewCache[post.id] = webView
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
                        if let content = post.htmlBodyWithWidth(self.view.frame.size.width) {
                            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
                            let htmlString = content
                            
                            webView.delegate = self
                            webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                            
                            self.bodyWebViewCache[post.id] = webView
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
                    if let height = self.bodyHeightCache[post.id] {} else {
                        return
                    }
                } else if let content = post.secondaryBody() {
                    if let height = self.secondaryBodyHeightCache[post.id] {} else {
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
        case "quote":
            return 2
        case "link":
            return 2
        case "chat":
            return post.dialogueEntries().count
        case "video":
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
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
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
            cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            return cell
        case "answer":
            switch AnswerRow.fromRaw(indexPath.row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(postQuestionTableViewCellIdentifier) as PostQuestionTableViewCell!
                cell.post = post
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "quote":
            switch QuoteRow.fromRaw(indexPath.row)! {
            case .Quote:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            case .Source:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "link":
            switch LinkRow.fromRaw(indexPath.row)! {
            case .Link:
                let cell = tableView.dequeueReusableCellWithIdentifier(postLinkTableViewCellIdentifier) as PostLinkTableViewCell!
                cell.post = post
                return cell
            case .Description:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "chat":
            let dialogueEntry = post.dialogueEntries()[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier(postDialogueEntryTableViewCellIdentifier) as PostDialogueEntryTableViewCell!
            cell.dialogueEntry = dialogueEntry
            return cell
        case "video":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            switch VideoRow.fromRaw(indexPath.row)! {
            case .Player:
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            return cell
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
                if let height = self.bodyHeightCache[post.id] {
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
            if let height = self.bodyHeightCache[post.id] {
                return height
            }
            return 0
        case "answer":
            switch AnswerRow.fromRaw(indexPath.row)! {
            case .Question:
                return PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.size.width)
            case .Answer:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "quote":
            switch QuoteRow.fromRaw(indexPath.row)! {
            case .Quote:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            case .Source:
                if let height = self.secondaryBodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "link":
            switch LinkRow.fromRaw(indexPath.row)! {
            case .Link:
                return PostLinkTableViewCell.heightForPost(post, width: tableView.frame.size.width)
            case .Description:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "chat":
            let dialogueEntry = post.dialogueEntries()[indexPath.row]
            return PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.size.width)
        case "video":
            switch VideoRow.fromRaw(indexPath.row)! {
            case .Player:
                if let height = self.secondaryBodyHeightCache[post.id] {
                    return height
                }
                return 0
            case .Caption:
                if let height = self.bodyHeightCache[post.id] {
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
        if let postId = self.bodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.bodyHeightCache[postId] = webView.documentHeight()
            self.bodyWebViewCache[postId] = nil
            self.reloadTable()
        } else if let postId = self.secondaryBodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.secondaryBodyHeightCache[postId] = webView.documentHeight()
            self.secondaryBodyWebViewCache[postId] = nil
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
