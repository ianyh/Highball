//
//  PostsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import FontAwesomeKit
import SafariServices
import SwiftyJSON
import TMTumblrSDK
import UIKit
import WebKit

enum TextRow: Int {
    case Title
    case Body
}

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

enum AudioRow: Int {
    case Player
    case Caption
}

let postCollectionViewCellIdentifier = "postCollectionViewCellIdentifier"

let postHeaderViewIdentifier = "postHeaderViewIdentifier"
let postFooterViewIdentifier = "postFooterViewIdentifier"
let titleTableViewCellIdentifier = "titleTableViewCellIdentifier"
let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"
let postLinkTableViewCellIdentifier = "postLinkTableViewCellIdentifier"
let postDialogueEntryTableViewCellIdentifier = "postDialogueEntryTableViewCellIdentifier"
let videoTableViewCellIdentifier = "videoTableViewCellIdentifier"
let youtubeTableViewCellIdentifier = "youtubeTableViewCellIdentifier"
let postTagsTableViewCellIdentifier = "postTagsTableViewCellIdentifier"

class PostsViewController: UITableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate, WKNavigationDelegate, TagsTableViewCellDelegate {
    private var heightComputationQueue: NSOperationQueue!
    private let requiredRefreshDistance: CGFloat = 60
    private let postParseQueue = dispatch_queue_create("postParseQueue", nil)
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var refreshControler: UIRefreshControl!
    private var reblogViewController: QuickReblogViewController?

    var webViewCache: Array<WKWebView>!
    var bodyWebViewCache: Dictionary<Int, WKWebView>!
    var bodyHeightCache: Dictionary<Int, CGFloat>!
    var secondaryBodyWebViewCache: Dictionary<Int, WKWebView>!
    var secondaryBodyHeightCache: Dictionary<Int, CGFloat>!
    var heightCache: Dictionary<NSIndexPath, CGFloat>!

    var posts: Array<Post>!
    var topID: Int? = nil

    var loadingTop: Bool = false {
        didSet {
            if !loadingTop {
                refreshControl?.endRefreshing()
            }
        }
    }
    var loadingBottom = false
    var lastPoint: CGPoint?
    var loadingCompletion: (() -> ())?

    override init(style: UITableViewStyle) {
        fatalError("Not implemented")
    }

    init() {
        super.init(style: .Plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = true

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("resignActive:"), name: UIApplicationWillResignActiveNotification, object: nil)

        heightComputationQueue = NSOperationQueue()
        heightComputationQueue.underlyingQueue = dispatch_get_main_queue()

        loadingTop = false
        loadingBottom = false

        webViewCache = Array<WKWebView>()
        bodyWebViewCache = Dictionary<Int, WKWebView>()
        bodyHeightCache = Dictionary<Int, CGFloat>()
        secondaryBodyWebViewCache = Dictionary<Int, WKWebView>()
        secondaryBodyHeightCache = Dictionary<Int, CGFloat>()
        heightCache = Dictionary<NSIndexPath, CGFloat>()

        let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

        loadingView.addSubview(activityIndicatorView)

        activityIndicatorView.startAnimating()
        activityIndicatorView.center = loadingView.center

        tableView.allowsSelection = false
        tableView.sectionHeaderHeight = 50
        tableView.separatorStyle = .None
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = loadingView

        tableView.registerClass(PostTableViewCell.self, forCellReuseIdentifier: postCollectionViewCellIdentifier)
        tableView.registerClass(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: postCollectionViewCellIdentifier)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("didLongPress:"))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.3

        if let gestureRecognizers = view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let gestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
                    gestureRecognizer.requireGestureRecognizerToFail(longPressGestureRecognizer)
                }
            }
        }

        view.addGestureRecognizer(longPressGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("didPan:"))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(self.panGestureRecognizer)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let posts = self.posts {
            if posts.count > 0 {
                return
            }
        }

        loadTop()
    }

    override func didReceiveMemoryWarning() {
        webViewCache.removeAll()
        super.didReceiveMemoryWarning()
    }

    func resignActive(notification: NSNotification) {
        webViewCache.removeAll()
    }

    func refresh(sender: UIRefreshControl) {
        loadTop()
    }

    func popWebView() -> WKWebView {
        let frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1)

        if webViewCache.count > 0 {
            let webView = webViewCache.removeAtIndex(0)
            webView.frame = frame
            return webView
        }

        let webView = WKWebView(frame: frame)
        webView.navigationDelegate = self
        return webView
    }

    func pushWebView(webView: WKWebView) {
        webViewCache.append(webView)
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func postsFromJSON(json: JSON) -> Array<Post> { return [] }
    func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) { NSException().raise() }

    func loadTop() {
        if loadingTop {
            return
        }

        loadingTop = true

        if let topID = topID {
            var sinceID = topID
            if posts.count > 0 {
                if let firstPost = posts.first {
                    sinceID = firstPost.id
                }
            }
            requestPosts(0, parameters: ["since_id" : "\(sinceID)", "reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) in
                if let e = error {
                    print(e)
                    self.loadingTop = false
                } else {
                    dispatch_async(self.postParseQueue, {
                        let posts = self.postsFromJSON(JSON(response))
                        dispatch_async(dispatch_get_main_queue()) {
                            self.processPosts(posts)
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.loadingCompletion = {
                                    if self.posts.count > 0 {
                                        self.posts = posts + self.posts
                                    } else {
                                        self.posts = posts
                                    }
                                    if let firstPost = posts.first {
                                        self.topID = firstPost.id
                                    }
                                    self.tableView.reloadData()
                                }
                                self.reloadTable()
                            })
                        }
                    })
                }
            }
        } else {
            requestPosts(0, parameters: ["reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) in
                if let e = error {
                    print(e)
                    self.loadingTop = false
                } else {
                    dispatch_async(self.postParseQueue, {
                        let posts = self.postsFromJSON(JSON(response))
                        dispatch_async(dispatch_get_main_queue()) {
                            self.processPosts(posts)
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.loadingCompletion = {
                                    self.posts = posts
                                    self.heightCache.removeAll()
                                    self.tableView.reloadData()
                                }
                                self.reloadTable()
                            })
                        }
                    })
                }
            }
        }
    }
    
    func loadMore() {
        if loadingTop || loadingBottom {
            return
        }

        if let posts = posts {
            if let lastPost = posts.last {
                loadingBottom = true
                requestPosts(posts.count, parameters: ["before_id" : "\(lastPost.id)", "reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        print(e)
                        self.loadingBottom = false
                    } else {
                        dispatch_async(self.postParseQueue, {
                            let posts = self.postsFromJSON(JSON(response))
                            dispatch_async(dispatch_get_main_queue()) {
                                self.processPosts(posts)

                                dispatch_async(dispatch_get_main_queue(), {
                                    self.loadingCompletion = {
                                        let indexSet = NSMutableIndexSet()
                                        for row in self.posts.count..<(self.posts.count + posts.count) {
                                            indexSet.addIndex(row)
                                        }

                                        self.posts.appendContentsOf(posts)
                                        self.tableView.insertSections(indexSet, withRowAnimation: .None)
                                    }
                                    self.reloadTable()
                                })
                            }
                        })
                    }
                }
            }
        }
    }

    func processPosts(posts: Array<Post>) {
        for post in posts {
            heightComputationQueue.addOperationWithBlock() {
                if let content = post.htmlBodyWithWidth(self.tableView.frame.width) {
                    let webView = self.popWebView()
                    let htmlString = content

                    self.bodyWebViewCache[post.id] = webView

                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                }
            }
            heightComputationQueue.addOperationWithBlock() {
                if let content = post.htmlSecondaryBodyWithWidth(self.tableView.frame.width) {
                    let webView = self.popWebView()
                    let htmlString = content
                    
                    self.secondaryBodyWebViewCache[post.id] = webView
                    
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                }
            }
        }
    }

    func reblogBlogName() -> (String) {
        return ""
    }

    func reloadTable() {
        if heightComputationQueue.operationCount > 0 {
            return
        }

        if bodyWebViewCache.count > 0 {
            return
        } else if secondaryBodyWebViewCache.count > 0 {
            return
        }

        if loadingTop || loadingBottom {
            loadingCompletion?()
        }

        loadingCompletion = nil
        loadingTop = false
        loadingBottom = false
    }
    
    func didLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            tableView.scrollEnabled = false
            let point = sender.locationInView(navigationController!.view)
            let collectionViewPoint = sender.locationInView(tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint) {
                if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                    let post = posts[indexPath.section]
                    let viewController = QuickReblogViewController()
                    
                    viewController.startingPoint = point
                    viewController.post = post
                    viewController.transitioningDelegate = self
                    viewController.modalPresentationStyle = UIModalPresentationStyle.Custom
                    
                    viewController.view.bounds = navigationController!.view.bounds
                    
                    navigationController!.view.addSubview(viewController.view)
                    
                    viewController.view.layoutIfNeeded()
                    viewController.viewDidAppear(false)
                    
                    reblogViewController = viewController
                }
            }
        } else if sender.state == UIGestureRecognizerState.Ended {
            tableView.scrollEnabled = true
            if let viewController = reblogViewController {
                let point = viewController.startingPoint
                let collectionViewPoint = tableView.convertPoint(point, fromView: navigationController!.view)
                if let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint) {
                    if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
                        let post = posts[indexPath.section]
                        
                        if let quickReblogAction = viewController.reblogAction() {
                            switch quickReblogAction {
                            case .Reblog(let reblogType):
                                let reblogViewController = TextReblogViewController()

                                reblogViewController.reblogType = reblogType
                                reblogViewController.post = post
                                reblogViewController.blogName = reblogBlogName()
                                reblogViewController.bodyHeight = bodyHeightCache[post.id]
                                reblogViewController.secondaryBodyHeight = secondaryBodyHeightCache[post.id]
                                reblogViewController.height = tableView(tableView, heightForRowAtIndexPath: indexPath)
                                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                                    reblogViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
                                } else {
                                    reblogViewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                                }
                                reblogViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                                reblogViewController.popoverPresentationController?.sourceView = view
                                reblogViewController.popoverPresentationController?.sourceRect = view.convertRect(cell.bounds, fromView: cell)
                                reblogViewController.popoverPresentationController?.backgroundColor = UIColor.clearColor()
                                reblogViewController.preferredContentSize = CGSize(width: tableView.frame.width, height: 480)
                                self.presentViewController(reblogViewController, animated: true, completion: nil)
                            case .Share:
                                let postItemProvider = PostItemProvider(placeholderItem: "")

                                postItemProvider.post = post
                                
                                var activityItems: Array<UIActivityItemProvider> = [ postItemProvider ]

                                if let image = cell.imageAtPoint(view.convertPoint(point, toView: cell)) {
                                    let imageItemProvider = ImageItemProvider(placeholderItem: image)

                                    imageItemProvider.image = image

                                    activityItems.append(imageItemProvider)
                                }

                                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                                activityViewController.popoverPresentationController?.sourceView = cell
                                activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: cell.center, size: CGSize(width: 1, height: 1))
                                self.presentViewController(activityViewController, animated: true, completion: nil)
                            case .Like:
                                if post.liked.boolValue {
                                    TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
                                        if let e = error {
                                            print(e)
                                        } else {
                                            post.liked = false
                                        }
                                    }
                                } else {
                                    TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
                                        if let e = error {
                                            print(e)
                                        } else {
                                            post.liked = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                viewController.view.removeFromSuperview()
            }
            
            reblogViewController = nil
        }
    }
    
    func didPan(sender: UIPanGestureRecognizer) {
        if let viewController = reblogViewController {
            viewController.updateWithPoint(sender.locationInView(viewController.view))
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return posts?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = posts![indexPath.section]
        let cell = tableView.dequeueReusableCellWithIdentifier(postCollectionViewCellIdentifier, forIndexPath: indexPath) as! PostTableViewCell
        
        cell.bodyHeight = bodyHeightCache[post.id]
        cell.secondaryBodyHeight = secondaryBodyHeightCache[post.id]
        cell.post = post
        
        cell.bodyTapHandler = { post, view in
            if let _ = view as? PhotosetRowTableViewCell {
                let viewController = ImagesViewController()
                viewController.post = post
                self.presentViewController(viewController, animated: true, completion: nil)
            } else if let videoCell = view as? VideoPlaybackCell {
                if videoCell.isPlaying() {
                    videoCell.stop()
                } else {
                    let viewController = VideoPlayController(completion: { play in
                        if play {
                            videoCell.play()
                        }
                    })
                    viewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
                    viewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    self.presentViewController(viewController, animated: true, completion: nil)
                }
            } else if let _ = view as? PostLinkTableViewCell {
                if let navigationController = self.navigationController {
                    navigationController.pushViewController(SFSafariViewController(URL: NSURL(string: post.urlString!)!), animated: true)
                }
            }
        }
        
        cell.tagTapHandler = { post, tag in
            if let navigationController = self.navigationController {
                navigationController.pushViewController(TagViewController(tag: tag), animated: true)
            }
        }
        
        cell.linkTapHandler = { post, url in
            if let navigationController = self.navigationController {
                if let host = url.host {
                    if let username = (host.characters.split { $0 == "." }).first {
                        navigationController.pushViewController(BlogViewController(blogName: String(username)), animated: true)
                        return
                    }
                }
                navigationController.pushViewController(SFSafariViewController(URL: url), animated: true)
            }
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.section]
        
        if let height = heightCache[indexPath] {
            return height
        }
        
        var height: CGFloat = 0.0
        
        switch post.type {
        case "photo":
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
            
            let postPhotos = post.photos
            var images: Array<PostPhoto>!
            var photosIndexStart = 0
            for layoutRow in post.layoutRows {
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + layoutRow)])
                
                let imageWidth = tableView.frame.width / CGFloat(images.count)
                let minHeight = floor(images.map { (image: PostPhoto) -> CGFloat in
                    let scale = image.height / image.width
                    return imageWidth * scale
                    }.reduce(CGFloat.max, combine: { min($0, $1) }))
                
                height += minHeight
                
                photosIndexStart += layoutRow
            }
        case "text":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
            }
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
        case "answer":
            height += PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.width)
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
        case "quote":
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
            if let secondaryBodyHeight = secondaryBodyHeightCache[post.id] {
                height += secondaryBodyHeight
            }
        case "link":
            height += PostLinkTableViewCell.heightForPost(post, width: tableView.frame.width)
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
        case "chat":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
            }
            for dialogueEntry in post.dialogueEntries {
                height += PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.width)
            }
        case "video":
            if let playerHeight = post.videoHeightWidthWidth(tableView.frame.width) {
                height += playerHeight
            } else {
                height += 320
            }
            
            if let bodyHeight = bodyHeightCache[post.id] {
                height += bodyHeight
            }
        default:
            height = 0
        }
        
        if post.tags.count > 0 {
            height += 30
        }
        
        heightCache[indexPath] = height
        
        return height
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(postCollectionViewCellIdentifier) as! PostHeaderView
        let post = posts![section] as Post
        view.post = post
        view.tapHandler = { post, view in
            if let _ = self.navigationController {
                if let rebloggedBlogName = post.rebloggedBlogName {
                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    alertController.popoverPresentationController?.sourceView = self.view
                    alertController.popoverPresentationController?.sourceRect = self.view.convertRect(view.bounds, fromView: view)
                    alertController.addAction(UIAlertAction(title: post.blogName, style: UIAlertActionStyle.Default, handler: { alertAction in
                        self.navigationController!.pushViewController(BlogViewController(blogName: post.blogName), animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: rebloggedBlogName, style: UIAlertActionStyle.Default, handler: { alertAction in
                        self.navigationController!.pushViewController(BlogViewController(blogName: rebloggedBlogName), animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { _ in }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    self.navigationController!.pushViewController(BlogViewController(blogName: post.blogName), animated: true)
                }
            }
        }
        return view
    }

    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? PostTableViewCell else {
            return
        }

        cell.endDisplay()
    }

    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

        if distanceFromBottom < 2000 {
            loadMore()
        }
    }

    // MARK: WKNavigationDelegate

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.getDocumentHeight { height in
            if let postId = self.bodyWebViewCache.keyForObject(webView, isEqual: ==) {
                self.bodyHeightCache[postId] = height
                self.bodyWebViewCache[postId] = nil
                self.reloadTable()
            } else if let postId = self.secondaryBodyWebViewCache.keyForObject(webView, isEqual: ==) {
                self.secondaryBodyHeightCache[postId] = height
                self.secondaryBodyWebViewCache[postId] = nil
                self.reloadTable()
            }

            self.pushWebView(webView)
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        if let postId = bodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.bodyHeightCache[postId] = 0
            self.bodyWebViewCache[postId] = nil
            self.reloadTable()
        } else if let postId = secondaryBodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.secondaryBodyHeightCache[postId] = 0
            self.secondaryBodyWebViewCache[postId] = nil
            self.reloadTable()
        }
        
        pushWebView(webView)
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ReblogTransitionAnimator()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = ReblogTransitionAnimator()
        
        animator.presenting = false
        
        return animator
    }

    // MARK: TagsTableViewCellDelegate

    func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
        navigationController?.pushViewController(TagViewController(tag: tag), animated: true)
    }
}

extension WKWebView {
    func getDocumentHeight(completion: (CGFloat) -> ()) {
        evaluateJavaScript("var body = document.body, html = document.documentElement; Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);", completionHandler: { result, error in
            if let _ = error {
                completion(0)
            } else if let height = JSON(result!).int {
                completion(CGFloat(height))
            } else {
                completion(0)
            }
        })
    }
}

extension Dictionary {
    func keyForObject(object: Value!, isEqual: (Value!, Value!) -> (Bool)) -> (Key?) {
        for key in self.keys {
            if isEqual(object, self[key] as Value!) {
                return key
            }
        }
        return nil
    }
}
