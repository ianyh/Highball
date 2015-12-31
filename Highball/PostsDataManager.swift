//
//  PostsDataManager.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import SwiftyJSON
import TMTumblrSDK
import UIKit

protocol PostsDataManagerDelegate {
    func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String: AnyObject], callback: TMAPICallback)
    func dataManager(dataManager: PostsDataManager, postsFromJSON json: JSON) -> [Post]
    func dataManagerDidReload(dataManager: PostsDataManager, indexSet: NSIndexSet?, completion: () -> ())
    func dataManagerDidComputeHeight(dataManager: PostsDataManager)
    func dataManager(dataManager: PostsDataManager, didEncounterError error: NSError)
}

class PostsDataManager {
    private let heightComputationQueue: NSOperationQueue!
    private let postParseQueue = dispatch_queue_create("postParseQueue", nil)

    private let webViewCache: WebViewCache
    private let postHeightCache: PostHeightCache
    private let delegate: PostsDataManagerDelegate

    private var heightCalculators: [Int: HeightCalculator] = [:]
    private var secondaryHeightCalculators: [Int: HeightCalculator] = [:]

    var posts: Array<Post>!
    var topID: Int? = nil

    var loadingTop = false
    var loadingBottom = false
    var lastPoint: CGPoint?

    var hasPosts: Bool {
        return self.posts != nil && posts.count > 0
    }
    var computingHeights: Bool {
        return heightComputationQueue.operationCount > 0 ||
            heightCalculators.count > 0 ||
            secondaryHeightCalculators.count > 0
    }

    init(webViewCache: WebViewCache, postHeightCache: PostHeightCache, delegate: PostsDataManagerDelegate) {
        self.webViewCache = webViewCache
        self.postHeightCache = postHeightCache
        self.delegate = delegate
        self.heightComputationQueue = NSOperationQueue()
        self.heightComputationQueue.underlyingQueue = dispatch_get_main_queue()
    }

    func loadTop(width: CGFloat) {
        if loadingTop {
            return
        }

        loadingTop = true

        var reloadCompletion: ([Post]) -> ()
        var parameters: [String: AnyObject]

        if let topID = topID {
            var sinceID = topID
            if let firstPost = posts.first {
                sinceID = firstPost.id
            }
            parameters = ["since_id": "\(sinceID)", "reblog_info": "true"]
            reloadCompletion = { posts in
                if self.posts.count > 0 {
                    self.posts = posts + self.posts
                } else {
                    self.posts = posts
                }
                if let firstPost = posts.first {
                    self.topID = firstPost.id
                }
            }
        } else {
            parameters = ["reblog_info": "true"]
            reloadCompletion = { posts in
                self.posts = posts
            }
        }

        delegate.dataManager(self, requestPostsWithCount: 0, parameters: parameters) { response, error in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.dataManager(self, didEncounterError: error)
                    self.loadingTop = false
                }
            } else {
                dispatch_async(self.postParseQueue) {
                    let posts = self.delegate.dataManager(self, postsFromJSON: JSON(response))
                    dispatch_async(dispatch_get_main_queue()) {
                        self.processPosts(posts, width: width)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.delegate.dataManagerDidReload(self, indexSet: nil) {
                                reloadCompletion(posts)
                            }
                        }
                    }
                }
            }
        }
    }

    func loadMore(width: CGFloat) {
        if loadingTop || loadingBottom {
            return
        }

        guard
            let posts = posts,
            let lastPost = posts.last
        else {
            return
        }

        let parameters = ["before_id" : "\(lastPost.id)", "reblog_info" : "true"]

        loadingBottom = true
        delegate.dataManager(self, requestPostsWithCount: posts.count, parameters: parameters) { response, error in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.dataManager(self, didEncounterError: error)
                    self.loadingBottom = false
                }
            } else {
                dispatch_async(self.postParseQueue) {
                    let posts = self.delegate.dataManager(self, postsFromJSON: JSON(response))
                    dispatch_async(dispatch_get_main_queue()) {
                        self.processPosts(posts, width: width)
                        dispatch_async(dispatch_get_main_queue()) {
                            let indexSet = NSMutableIndexSet()
                            for row in self.posts.count..<(self.posts.count + posts.count) {
                                indexSet.addIndex(row)
                            }

                            self.delegate.dataManagerDidReload(self, indexSet: indexSet) {
                                self.posts.appendContentsOf(posts)
                            }
                        }
                    }
                }
            }
        }
    }

    func processPosts(posts: [Post], width: CGFloat) {
        for post in posts {
            heightComputationQueue.addOperationWithBlock() {
                let webView = self.webViewCache.popWebView()
                let heightCalculator = HeightCalculator(post: post, width: width, webView: webView)

                self.heightCalculators[post.id] = heightCalculator

                heightCalculator.calculateHeight { height in
                    self.webViewCache.pushWebView(webView)
                    self.heightCalculators[post.id] = nil
                    self.postHeightCache.setBodyHeight(height, forPost: post)
                    self.delegate.dataManagerDidComputeHeight(self)
                }
            }
            heightComputationQueue.addOperationWithBlock() {
                let webView = self.webViewCache.popWebView()
                let heightCalculator = HeightCalculator(post: post, width: width, webView: webView)

                self.secondaryHeightCalculators[post.id] = heightCalculator

                heightCalculator.calculateHeight(true) { height in
                    self.webViewCache.pushWebView(webView)
                    self.secondaryHeightCalculators[post.id] = nil
                    self.postHeightCache.setSecondaryBodyHeight(height, forPost: post)
                    self.delegate.dataManagerDidComputeHeight(self)
                }
            }
        }
    }
}
