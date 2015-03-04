//
//  PostsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

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
let titleTableViewCellIdentifier = "titleTableViewCellIdentifier"
let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"
let postLinkTableViewCellIdentifier = "postLinkTableViewCellIdentifier"
let postDialogueEntryTableViewCellIdentifier = "postDialogueEntryTableViewCellIdentifier"
let videoTableViewCellIdentifier = "videoTableViewCellIdentifier"
let youtubeTableViewCellIdentifier = "youtubeTableViewCellIdentifier"
let postTagsTableViewCellIdentifier = "postTagsTableViewCellIdentifier"

class PostsViewController: UICollectionViewController, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate, WKNavigationDelegate, TagsTableViewCellDelegate {
    private var columnCount: CGFloat {
        get {
            if let waterfallLayout = self.collectionView?.collectionViewLayout as? CHTCollectionViewWaterfallLayout {
                return CGFloat(waterfallLayout.columnCount)
            }
            return 0.0
        }
    }
    private var heightComputationQueue: NSOperationQueue!
    private let requiredRefreshDistance: CGFloat = 60
    private let postParseQueue = dispatch_queue_create("postParseQueue", nil)
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
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
            if let navigationController = self.navigationController {
                if self.loadingTop {
                    navigationController.setIndeterminate(true)
                    navigationController.showProgress()
                } else {
                    navigationController.setIndeterminate(false)
                    navigationController.cancelProgress()
                }
            }
        }
    }
    var loadingBottom = false
    var lastPoint: CGPoint?
    var loadingCompletion: (() -> ())?

    override init(collectionViewLayout layout: UICollectionViewLayout!) {
        fatalError("Not implemented")
    }

    required override init() {
        let waterfallLayout = CHTCollectionViewWaterfallLayout()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            waterfallLayout.columnCount = 2
        } else {
            waterfallLayout.columnCount = 1
        }
        waterfallLayout.sectionInset = UIEdgeInsetsZero
        waterfallLayout.minimumInteritemSpacing = 0.0
        waterfallLayout.minimumColumnSpacing = 0.0
        super.init(collectionViewLayout: waterfallLayout)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = true

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("resignActive:"), name: UIApplicationWillResignActiveNotification, object: nil)

        self.heightComputationQueue = NSOperationQueue()
        self.heightComputationQueue.underlyingQueue = dispatch_get_main_queue()

        self.loadingTop = false
        self.loadingBottom = false

        self.webViewCache = Array<WKWebView>()
        self.bodyWebViewCache = Dictionary<Int, WKWebView>()
        self.bodyHeightCache = Dictionary<Int, CGFloat>()
        self.secondaryBodyWebViewCache = Dictionary<Int, WKWebView>()
        self.secondaryBodyHeightCache = Dictionary<Int, CGFloat>()
        self.heightCache = Dictionary<NSIndexPath, CGFloat>()

        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.showsHorizontalScrollIndicator = false
        self.collectionView?.showsVerticalScrollIndicator = false
        self.collectionView?.bounces = true
        self.collectionView?.alwaysBounceHorizontal = false
        self.collectionView?.alwaysBounceVertical = true
        self.collectionView?.allowsSelection = false
        self.collectionView?.backgroundColor = UIColor.whiteColor()

        self.collectionView?.registerClass(PostCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: postCollectionViewCellIdentifier)
        
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("didLongPress:"))
        self.longPressGestureRecognizer.delegate = self
        self.longPressGestureRecognizer.minimumPressDuration = 0.3
        self.view.addGestureRecognizer(self.longPressGestureRecognizer)

        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("didPan:"))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)

        let menuIcon = FAKIonIcons.iosGearOutlineIconWithSize(30);
        let menuIconImage = menuIcon.imageWithSize(CGSize(width: 30, height: 30))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: menuIconImage,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: Selector("navigate:event:")
        )
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let posts = self.posts {
            if countElements(posts) > 0 {
                return
            }
        }

        self.loadTop()
    }

    override func didReceiveMemoryWarning() {
        self.webViewCache.removeAll()
        super.didReceiveMemoryWarning()
    }

    func resignActive(notification: NSNotification) {
        self.webViewCache.removeAll()
    }

    func popWebView() -> WKWebView {
        let frame = CGRect(x: 0, y: 0, width: self.collectionView!.frame.size.width / self.columnCount, height: 1)

        if countElements(self.webViewCache) > 0 {
            let webView = self.webViewCache.removeAtIndex(0)
            webView.frame = frame
            return webView
        }

        let webView = WKWebView(frame: frame)
        webView.navigationDelegate = self
        return webView
    }

    func pushWebView(webView: WKWebView) {
        self.webViewCache.append(webView)
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func postsFromJSON(json: JSON) -> Array<Post> { return [] }
    func requestPosts(parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) { NSException().raise() }

    func loadTop() {
        if self.loadingTop {
            return
        }

        self.loadingTop = true

        if let topID = self.topID {
            var sinceID = topID
            if self.posts.count > 0 {
                if let firstPost = self.posts.first {
                    sinceID = firstPost.id
                }
            }
            self.requestPosts(["since_id" : "\(sinceID)", "reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) in
                if let e = error {
                    println(e)
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
                                    self.collectionView!.reloadData()
                                }
                                self.reloadTable()
                            })
                        }
                    })
                }
            }
        } else {
            self.requestPosts(["reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) in
                if let e = error {
                    println(e)
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
                                    self.collectionView!.reloadData()
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
        if self.loadingTop || self.loadingBottom {
            return
        }

        if let posts = self.posts {
            if let lastPost = posts.last {
                self.loadingBottom = true
                self.requestPosts(["max_id" : "\(lastPost.id)", "reblog_info" : "true"]) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        println(e)
                        self.loadingBottom = false
                    } else {
                        dispatch_async(self.postParseQueue, {
                            let posts = self.postsFromJSON(JSON(response))
                            dispatch_async(dispatch_get_main_queue()) {
                                self.processPosts(posts)

                                dispatch_async(dispatch_get_main_queue(), {
                                    self.loadingCompletion = {
                                        let indexSet = NSIndexSet(indexesInRange: NSMakeRange(self.posts.count, posts.count))

                                        self.posts.extend(posts)
                                        
                                        self.collectionView!.reloadData()
//                                        self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
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
            self.heightComputationQueue.addOperationWithBlock() {
                if let content = post.htmlBodyWithWidth(self.collectionView!.frame.size.width / self.columnCount) {
                    let webView = self.popWebView()
                    let htmlString = content

                    self.bodyWebViewCache[post.id] = webView

                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                }
            }
            self.heightComputationQueue.addOperationWithBlock() {
                if let content = post.htmlSecondaryBodyWithWidth(self.collectionView!.frame.size.width / self.columnCount) {
                    let webView = self.popWebView()
                    let htmlString = content
                    
                    self.secondaryBodyWebViewCache[post.id] = webView
                    
                    webView.loadHTMLString(htmlString, baseURL: NSURL(string: ""))
                }
            }
        }
    }

    func navigate(sender: UIBarButtonItem, event: UIEvent) {
        if let touches = event.allTouches() {
            if let touch = touches.anyObject() as? UITouch {
                if let navigationController = self.navigationController {
                    let viewController = QuickNavigateController()
                    
                    viewController.startingPoint = touch.locationInView(self.view)
                    viewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                    viewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                    viewController.view.bounds = navigationController.view.bounds

                    viewController.completion = { navigateOption in
                        if let option = navigateOption {
                            switch(option) {
                            case .Dashboard:
                                navigationController.setViewControllers([DashboardViewController()], animated: false)
                            case .Likes:
                                navigationController.setViewControllers([LikesViewController()], animated: false)
                            case .Settings:
                                navigationController.dismissViewControllerAnimated(true, completion: { () -> Void in
                                    let settingsViewController = SettingsViewController(style: UITableViewStyle.Grouped)
                                    let settingsNavigationViewController = UINavigationController(rootViewController: settingsViewController)
                                    navigationController.presentViewController(settingsNavigationViewController, animated: true, completion: nil)
                                })
                                return
                            }
                        }
                        navigationController.dismissViewControllerAnimated(true, completion: nil)
                    }
                    
                    navigationController.presentViewController(viewController, animated: true, completion: nil)
                }
            }
        }
    }

    func reblogBlogName() -> (String) {
        return ""
    }

    func reloadTable() {
        if self.heightComputationQueue.operationCount > 0 {
            return
        }

        if self.bodyWebViewCache.count > 0 {
            return
        } else if self.secondaryBodyWebViewCache.count > 0 {
            return
        }

        if self.loadingTop || self.loadingBottom {
            if let completion = self.loadingCompletion {
                completion()
            }
        }

        self.loadingCompletion = nil
        self.loadingTop = false
        self.loadingBottom = false
    }
    
    func didLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            self.collectionView!.scrollEnabled = false
            let point = sender.locationInView(self.navigationController!.view)
            let collectionViewPoint = sender.locationInView(self.collectionView!)
            if let indexPath = self.collectionView?.indexPathForItemAtPoint(collectionViewPoint) {
                if let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) {
                    let post = self.posts[indexPath.row]
                    let viewController = QuickReblogViewController()
                    
                    viewController.startingPoint = point
                    viewController.post = post
                    viewController.transitioningDelegate = self
                    viewController.modalPresentationStyle = UIModalPresentationStyle.Custom
                    
                    viewController.view.bounds = self.navigationController!.view.bounds
                    
                    self.navigationController!.view.addSubview(viewController.view)
                    
                    viewController.view.layoutIfNeeded()
                    viewController.viewDidAppear(false)
                    
                    self.reblogViewController = viewController
                }
            }
        } else if sender.state == UIGestureRecognizerState.Ended {
            self.collectionView!.scrollEnabled = true
            if let viewController = self.reblogViewController {
                let point = viewController.startingPoint
                let collectionViewPoint = self.collectionView!.convertPoint(point, fromView: self.navigationController!.view)
                if let indexPath = self.collectionView!.indexPathForItemAtPoint(collectionViewPoint) {
                    if let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as? PostCollectionViewCell {
                        let post = self.posts[indexPath.row]
                        
                        if let quickReblogAction = viewController.reblogAction() {
                            switch quickReblogAction {
                            case .Reblog(let reblogType):
                                let reblogViewController = TextReblogViewController()

                                reblogViewController.reblogType = reblogType
                                reblogViewController.post = post
                                reblogViewController.blogName = self.reblogBlogName()
                                reblogViewController.bodyHeight = self.bodyHeightCache[post.id]
                                reblogViewController.secondaryBodyHeight = self.secondaryBodyHeightCache[post.id]
                                reblogViewController.height = self.collectionView(self.collectionView!, layout: self.collectionView!.collectionViewLayout, sizeForItemAtIndexPath: indexPath).height
                                reblogViewController.width = self.collectionView!.frame.size.width
//                                reblogViewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                                    reblogViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
                                } else {
                                    reblogViewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                                }
                                reblogViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                                reblogViewController.popoverPresentationController?.sourceView = cell
                                reblogViewController.popoverPresentationController?.sourceRect = cell.frame
                                reblogViewController.popoverPresentationController?.backgroundColor = UIColor.clearColor()
                                reblogViewController.preferredContentSize = CGSize(width: self.collectionView!.frame.size.width / self.columnCount, height: 480)
                                self.presentViewController(reblogViewController, animated: true, completion: nil)
                            case .Share:
                                let postItemProvider = PostItemProvider(placeholderItem: "")

                                postItemProvider.post = post
                                
                                var activityItems: Array<UIActivityItemProvider> = [ postItemProvider ]

                                if let image = cell.imageAtPoint(self.view.convertPoint(point, toView: cell)) {
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
                                    TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey, callback: { (response, error) -> Void in
                                        if let e = error {
                                            println(e)
                                        } else {
                                            post.liked = false
                                        }
                                    })
                                } else {
                                    TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey, callback: { (response, error) -> Void in
                                        if let e = error {
                                            println(e)
                                        } else {
                                            post.liked = true
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
                
                viewController.view.removeFromSuperview()
            }
            
            self.reblogViewController = nil
        }
    }
    
    func didPan(sender: UIPanGestureRecognizer) {
        if let viewController = self.reblogViewController {
            viewController.updateWithPoint(sender.locationInView(viewController.view))
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let posts = self.posts {
            return posts.count
        }
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let post = self.posts![indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(postCollectionViewCellIdentifier, forIndexPath: indexPath) as PostCollectionViewCell

        cell.bodyHeight = self.bodyHeightCache[post.id]
        cell.secondaryBodyHeight = self.secondaryBodyHeightCache[post.id]
        cell.post = post

        cell.headerTapHandler = { post, view in
            if let navigationController = self.navigationController {
                if let rebloggedBlogName = post.rebloggedBlogName {
                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    alertController.popoverPresentationController?.sourceView = self.view
                    alertController.popoverPresentationController?.sourceRect = self.view.convertRect(view.frame, fromView: view)
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

        cell.bodyTapHandler = { post, view in
            if let photosetRowCell = view as? PhotosetRowTableViewCell {
                let viewController = ImagesViewController()
                viewController.post = post
                self.presentViewController(viewController, animated: true, completion: nil)
            } else if let videoCell = cell as? VideoPlaybackCell {
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
            }
        }

        return cell
    }

    // MARK: CHTCollectionViewDelegateWaterfallLayout

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        let post = self.posts[indexPath.row]

        if let height = self.heightCache[indexPath] {
            return CGSize(width: collectionView.frame.size.width, height: height)
        }
        
        var height: CGFloat = 50.0 * self.columnCount
        
        switch post.type {
        case "photo":
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
            
            let postPhotos = post.photos
            var images: Array<PostPhoto>!
            var photosIndexStart = 0
            for layoutRow in post.layoutRows {
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + layoutRow)])

                let imageWidth = collectionView.frame.size.width / (self.columnCount * CGFloat(images.count))
                let minHeight = floor(images.map { (image: PostPhoto) -> CGFloat in
                    let scale = image.height / image.width
                    return imageWidth * scale
                    }.reduce(CGFloat.max, combine: { min($0, $1) }))

                height += minHeight * self.columnCount

                photosIndexStart += layoutRow
            }
        case "text":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: collectionView.frame.size.width / self.columnCount) * self.columnCount
            }
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
        case "answer":
            height += PostQuestionTableViewCell.heightForPost(post, width: collectionView.frame.size.width / self.columnCount) * self.columnCount
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
        case "quote":
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
            if let secondaryBodyHeight = self.secondaryBodyHeightCache[post.id] {
                height += secondaryBodyHeight * self.columnCount
            }
        case "link":
            height += PostLinkTableViewCell.heightForPost(post, width: collectionView.frame.size.width / self.columnCount) * self.columnCount
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
        case "chat":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: collectionView.frame.size.width / self.columnCount) * self.columnCount
            }
            for dialogueEntry in post.dialogueEntries {
                height += PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: collectionView.frame.size.width / self.columnCount) * self.columnCount
            }
        case "video":
            if let playerHeight = post.videoHeightWidthWidth(collectionView.frame.size.width / self.columnCount) {
                height += playerHeight * self.columnCount
            } else {
                height += 320
            }
            
            if let bodyHeight = self.bodyHeightCache[post.id] {
                height += bodyHeight * self.columnCount
            }
        default:
            height = 0
        }

        if post.tags.count > 0 {
            height += 30 * self.columnCount
        }

        self.heightCache[indexPath] = height

        return CGSize(width: collectionView.frame.size.width, height: height)
    }

    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? PostCollectionViewCell {
            cell.endDisplay()
        }
    }

    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

        if distanceFromBottom < 2000 {
            self.loadMore()
        }

        if !self.loadingTop {
            if let navigationController = self.navigationController {
                if !navigationController.getIndeterminate() {
                    if scrollView.contentOffset.y < 0 {
                        let distanceFromTop = scrollView.contentOffset.y + scrollView.contentInset.top + requiredRefreshDistance
                        let progress = 1 - max(min(distanceFromTop / requiredRefreshDistance, 1), 0)
                        navigationController.showProgress()
                        navigationController.setProgress(progress, animated: false)
                    } else {
                        navigationController.cancelProgress()
                    }
                }
            }
        }
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let distanceFromTop = scrollView.contentOffset.y + scrollView.contentInset.top
        if -distanceFromTop > self.requiredRefreshDistance {
            self.loadTop()
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
        if let postId = self.bodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.bodyHeightCache[postId] = 0
            self.bodyWebViewCache[postId] = nil
            self.reloadTable()
        } else if let postId = self.secondaryBodyWebViewCache.keyForObject(webView, isEqual: ==) {
            self.secondaryBodyHeightCache[postId] = 0
            self.secondaryBodyWebViewCache[postId] = nil
            self.reloadTable()
        }
        
        self.pushWebView(webView)
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
        if let navigationController = self.navigationController {
            navigationController.pushViewController(TagViewController(tag: tag), animated: true)
        }
    }
}

extension WKWebView {
    func getDocumentHeight(completion: (CGFloat) -> ()) {
        self.evaluateJavaScript("var body = document.body, html = document.documentElement;Math.max( body.scrollHeight, body.offsetHeight,html.clientHeight, html.scrollHeight, html.offsetHeight );", completionHandler: { result, error in
            if let e = error {
                completion(0)
            } else if let height = JSON(result).int {
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
