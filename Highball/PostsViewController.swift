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
import XExtensionItem

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

class PostsViewController: UITableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate, TagsTableViewCellDelegate {
    private var heightComputationQueue: NSOperationQueue!
    private let requiredRefreshDistance: CGFloat = 60
    private let postParseQueue = dispatch_queue_create("postParseQueue", nil)
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var refreshControler: UIRefreshControl!
    private var reblogViewController: QuickReblogViewController?

    var webViewCache: Array<WKWebView>!
    var bodyHeightCache: Dictionary<Int, CGFloat>!
    var secondaryBodyHeightCache: Dictionary<Int, CGFloat>!
    var heightCache: Dictionary<NSIndexPath, CGFloat>!

    private var heightCalculators = [Int: HeightCalculator]()
    private var secondaryHeightCalculators = [Int: HeightCalculator]()

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
        bodyHeightCache = Dictionary<Int, CGFloat>()
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

        tableView.registerClass(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.cellIdentifier)
        tableView.registerClass(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: PostHeaderView.viewIdentifier)
        
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
        webViewCache?.removeAll()
        super.didReceiveMemoryWarning()
    }

    func resignActive(notification: NSNotification) {
        webViewCache?.removeAll()
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
                if let error = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.presentError(error)
                        self.loadingTop = false
                    }
                } else {
                    dispatch_async(self.postParseQueue) {
                        let posts = self.postsFromJSON(JSON(response))
                        dispatch_async(dispatch_get_main_queue()) {
                            self.processPosts(posts)
                            
                            dispatch_async(dispatch_get_main_queue()) {
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
                            }
                        }
                    }
                }
            }
        } else {
            requestPosts(0, parameters: ["reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) in
                if let error = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.presentError(error)
                        self.loadingTop = false
                    }
                } else {
                    dispatch_async(self.postParseQueue) {
                        let posts = self.postsFromJSON(JSON(response))
                        dispatch_async(dispatch_get_main_queue()) {
                            self.processPosts(posts)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.loadingCompletion = {
                                    self.posts = posts
                                    self.heightCache.removeAll()
                                    self.tableView.reloadData()
                                }
                                self.reloadTable()
                            }
                        }
                    }
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
                    if let error = error {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.presentError(error)
                            self.loadingBottom = false
                        }
                    } else {
                        dispatch_async(self.postParseQueue) {
                            let posts = self.postsFromJSON(JSON(response))
                            dispatch_async(dispatch_get_main_queue()) {
                                self.processPosts(posts)

                                dispatch_async(dispatch_get_main_queue()) {
                                    self.loadingCompletion = {
                                        let indexSet = NSMutableIndexSet()
                                        for row in self.posts.count..<(self.posts.count + posts.count) {
                                            indexSet.addIndex(row)
                                        }

                                        self.posts.appendContentsOf(posts)
                                        self.tableView.insertSections(indexSet, withRowAnimation: .None)
                                    }
                                    self.reloadTable()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func presentError(error: NSError) {
        let alertController = UIAlertController(title: "Error", message: "Hit an error trying to load posts. \(error.localizedDescription)", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alertController.addAction(action)

        presentViewController(alertController, animated: true, completion: nil)

        print(error)
    }

    func processPosts(posts: Array<Post>) {
        for post in posts {
            heightComputationQueue.addOperationWithBlock() {
                let width = self.tableView.frame.width
                let webView = self.popWebView()
                let heightCalculator = HeightCalculator(post: post, width: width, webView: webView)

                self.heightCalculators[post.id] = heightCalculator

                heightCalculator.calculateHeight { height in
                    self.pushWebView(webView)
                    self.heightCalculators[post.id] = nil
                    self.bodyHeightCache[post.id] = height
                    self.reloadTable()
                }
            }
            heightComputationQueue.addOperationWithBlock() {
                let width = self.tableView.frame.width
                let webView = self.popWebView()
                let heightCalculator = HeightCalculator(post: post, width: width, webView: webView)

                self.secondaryHeightCalculators[post.id] = heightCalculator

                heightCalculator.calculateHeight(true) { height in
                    self.pushWebView(webView)
                    self.secondaryHeightCalculators[post.id] = nil
                    self.secondaryBodyHeightCache[post.id] = height
                    self.reloadTable()
                }
            }
        }
    }

    private func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }

    func reloadTable() {
        guard
            heightComputationQueue.operationCount == 0 &&
            heightCalculators.count == 0 &&
            secondaryHeightCalculators.count == 0
        else {
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
                                let navigationController = UINavigationController(rootViewController: reblogViewController)

                                reblogViewController.reblogType = reblogType
                                reblogViewController.post = post
                                reblogViewController.blogName = reblogBlogName()
                                reblogViewController.bodyHeight = bodyHeightCache[post.id]
                                reblogViewController.secondaryBodyHeight = secondaryBodyHeightCache[post.id]
                                reblogViewController.height = tableView(tableView, heightForRowAtIndexPath: indexPath)

                                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                                    navigationController.modalPresentationStyle = .Popover
                                } else {
                                    navigationController.modalPresentationStyle = .OverFullScreen
                                }
                                navigationController.modalTransitionStyle = .CrossDissolve
                                navigationController.popoverPresentationController?.sourceView = view
                                navigationController.popoverPresentationController?.sourceRect = view.convertRect(cell.bounds, fromView: cell)
                                navigationController.popoverPresentationController?.backgroundColor = UIColor.clearColor()
                                navigationController.preferredContentSize = CGSize(width: tableView.frame.width, height: 480)

                                self.presentViewController(navigationController, animated: true, completion: nil)
                            case .Share:
                                let extensionItemSource = XExtensionItemSource(URL: NSURL(string: post.urlString!)!)
                                var additionalAttachments: [AnyObject] = post.photos.map { $0.urlWithWidth(CGFloat.max) }

                                if let image = cell.imageAtPoint(view.convertPoint(point, toView: cell)) {
                                    additionalAttachments.append(image)
                                }

                                extensionItemSource.additionalAttachments = additionalAttachments

                                let activityViewController = UIActivityViewController(activityItems: [extensionItemSource], applicationActivities: nil)
                                activityViewController.popoverPresentationController?.sourceView = cell
                                activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: cell.center, size: CGSize(width: 1, height: 1))

                                presentViewController(activityViewController, animated: true, completion: nil)
                            case .Like:
                                if post.liked.boolValue {
                                    TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
                                        if let error = error {
                                            self.presentError(error)
                                        } else {
                                            post.liked = false
                                        }
                                    }
                                } else {
                                    TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
                                        if let error = error {
                                            self.presentError(error)
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
        let cell = tableView.dequeueReusableCellWithIdentifier(PostTableViewCell.cellIdentifier, forIndexPath: indexPath) as! PostTableViewCell
        
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
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(PostHeaderView.viewIdentifier) as! PostHeaderView
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
