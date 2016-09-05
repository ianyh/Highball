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

public protocol PostsDataManagerDelegate: class {
	func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String: AnyObject], callback: TMAPICallback)
	func dataManagerPostsJSONKey(dataManager: PostsDataManager) -> String?
	func dataManagerDidReload(dataManager: PostsDataManager, indexSet: NSIndexSet?, completion: () -> ())
	func dataManagerDidComputeHeight(dataManager: PostsDataManager)
	func dataManager(dataManager: PostsDataManager, didEncounterError error: NSError)
}

public class PostsDataManager {
	private let heightComputationQueue: NSOperationQueue!
	private let postParseQueue = dispatch_queue_create("postParseQueue", nil)

	private let postHeightCache: PostHeightCache
	private weak var delegate: PostsDataManagerDelegate?

	private var heightCalculators: [Int: HeightCalculator] = [:]
	private var secondaryHeightCalculators: [Int: HeightCalculator] = [:]
	private var bodyHeightCalculators: [String: HeightCalculator] = [:]

	public var posts: Array<Post>!
	public var topID: Int?
	public var cursor: Int?

	public var loadingTop = false
	public var loadingBottom = false
	public var lastPoint: CGPoint?

	public var hasPosts: Bool {
		return self.posts != nil && posts.count > 0
	}
	public var computingHeights: Bool {
		return heightComputationQueue.operationCount > 0 ||
			heightCalculators.count > 0 ||
			secondaryHeightCalculators.count > 0 ||
			bodyHeightCalculators.count > 0
	}

	public init(postHeightCache: PostHeightCache, delegate: PostsDataManagerDelegate) {
		self.postHeightCache = postHeightCache
		self.delegate = delegate
		self.heightComputationQueue = NSOperationQueue()
		self.heightComputationQueue.underlyingQueue = dispatch_get_main_queue()
	}

	public func loadTop(width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		loadingTop = true

		var reloadCompletion: ([Post]) -> ()
		var parameters: [String: AnyObject]

		if let topID = topID {
			parameters = ["since_id": "\(topID)", "reblog_info": "true"]
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
			reloadCompletion = { (posts: [Post]) in
				self.posts = posts
				self.cursor = posts.last?.id
			}
		}

		delegate?.dataManager(self, requestPostsWithCount: 0, parameters: parameters) { response, error in
			if let error = error {
				dispatch_async(dispatch_get_main_queue()) {
					self.delegate?.dataManager(self, didEncounterError: error)
					self.loadingTop = false
				}
			} else {
				dispatch_async(self.postParseQueue) {
					let posts = { () -> [Post] in
						if let postsKey = self.delegate?.dataManagerPostsJSONKey(self) {
							return JSON(response)[postsKey].array?.map { Post.from($0.dictionaryObject!) }.flatMap { $0 } ?? []
						} else {
							return JSON(response).array?.map { Post.from($0.dictionaryObject!) }.flatMap { $0 } ?? []
						}
					}()

					dispatch_async(dispatch_get_main_queue()) {
						self.processPosts(posts, width: width)
						dispatch_async(dispatch_get_main_queue()) {
							var indexSet: NSIndexSet?
							if self.topID != nil {
								// swiftlint:disable legacy_constructor
								indexSet = NSIndexSet(indexesInRange: NSMakeRange(0, posts.count))
								// swiftlint:enable legacy_constructor
							}
							self.delegate?.dataManagerDidReload(self, indexSet: indexSet) {
								reloadCompletion(posts)
							}
						}
					}
				}
			}
		}
	}

	public func loadMore(width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		guard let posts = posts, cursor = cursor else {
			return
		}

		let parameters = ["before_id" : "\(cursor)", "reblog_info" : "true"]

		loadingBottom = true
		delegate?.dataManager(self, requestPostsWithCount: posts.count, parameters: parameters) { response, error in
			if let error = error {
				dispatch_async(dispatch_get_main_queue()) {
					self.delegate?.dataManager(self, didEncounterError: error)
					self.loadingBottom = false
				}
			} else {
				dispatch_async(self.postParseQueue) {
					let posts = { () -> [Post] in
						if let postsKey = self.delegate?.dataManagerPostsJSONKey(self) {
							return JSON(response)[postsKey].array?.map { Post.from($0.dictionaryObject!) }.flatMap { $0 } ?? []
						} else {
							return JSON(response).array?.map { Post.from($0.dictionaryObject!) }.flatMap { $0 } ?? []
						}
					}()

					dispatch_async(dispatch_get_main_queue()) {
						self.processPosts(posts, width: width)
						dispatch_async(dispatch_get_main_queue()) {
							let indexSet = NSMutableIndexSet()
							for row in self.posts.count..<(self.posts.count + posts.count) {
								indexSet.addIndex(row)
							}

							self.delegate?.dataManagerDidReload(self, indexSet: indexSet) {
								self.posts.appendContentsOf(posts)
								self.cursor = posts.last?.id
							}
						}
					}
				}
			}
		}
	}

	public func toggleLikeForPostAtIndex(index: Int) {
		var post = posts[index]

		if post.liked.boolValue {
			TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
				if let error = error {
					print(error)
				} else {
					post.liked = false
					self.posts[index] = post
				}
			}
		} else {
			TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
				if let error = error {
					print(error)
				} else {
					post.liked = true
					self.posts[index] = post
				}
			}
		}
	}

	private func processPosts(posts: [Post], width: CGFloat) {
		for post in posts {
			heightComputationQueue.addOperationWithBlock() {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.heightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight { height in
					self.heightCalculators[post.id] = nil
					self.postHeightCache.setBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			heightComputationQueue.addOperationWithBlock() {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.secondaryHeightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight(true) { height in
					self.secondaryHeightCalculators[post.id] = nil
					self.postHeightCache.setSecondaryBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			for (index, _) in post.trailData.enumerate() {
				heightComputationQueue.addOperationWithBlock() { height in
					let heightCalculator = HeightCalculator(post: post, width: width)
					let key = "\(post.id):\(index)"
					self.bodyHeightCalculators[key] = heightCalculator
					heightCalculator.calculateBodyHeightAtIndex(index) { height in
						self.bodyHeightCalculators[key] = nil
						self.postHeightCache.setBodyHeight(height, forPost: post, atIndex: index)
						self.delegate?.dataManagerDidComputeHeight(self)
					}
				}
			}
		}
	}
}
