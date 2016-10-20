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
	func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String: AnyObject], callback: @escaping TMAPICallback)
	func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String?
	func dataManagerDidReload(_ dataManager: PostsDataManager, indexSet: IndexSet?, completion: () -> ())
	func dataManagerDidComputeHeight(_ dataManager: PostsDataManager)
	func dataManager(_ dataManager: PostsDataManager, didEncounterError error: NSError)
}

open class PostsDataManager {
	fileprivate let heightComputationQueue: OperationQueue!
	fileprivate let postParseQueue = DispatchQueue(label: "postParseQueue", attributes: [])

	fileprivate let postHeightCache: PostHeightCache
	fileprivate weak var delegate: PostsDataManagerDelegate?

	fileprivate var heightCalculators: [Int: HeightCalculator] = [:]
	fileprivate var secondaryHeightCalculators: [Int: HeightCalculator] = [:]
	fileprivate var bodyHeightCalculators: [String: HeightCalculator] = [:]

	open var posts: Array<Post>!
	open var topID: Int?
	open var cursor: Int?

	open var loadingTop = false
	open var loadingBottom = false
	open var lastPoint: CGPoint?

	open var hasPosts: Bool {
		return self.posts != nil && posts.count > 0
	}
	open var computingHeights: Bool {
		return heightComputationQueue.operationCount > 0 ||
			heightCalculators.count > 0 ||
			secondaryHeightCalculators.count > 0 ||
			bodyHeightCalculators.count > 0
	}

	public init(postHeightCache: PostHeightCache, delegate: PostsDataManagerDelegate) {
		self.postHeightCache = postHeightCache
		self.delegate = delegate
		self.heightComputationQueue = OperationQueue()
		self.heightComputationQueue.underlyingQueue = DispatchQueue.main
	}

	open func loadTop(_ width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		loadingTop = true

		var reloadCompletion: ([Post]) -> ()
		var parameters: [String: AnyObject]

		if let topID = topID {
			parameters = ["since_id": "\(topID)" as AnyObject, "reblog_info": "true" as AnyObject]
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
			parameters = ["reblog_info": "true" as AnyObject]
			reloadCompletion = { (posts: [Post]) in
				self.posts = posts
				self.cursor = posts.last?.id
			}
		}

		delegate?.dataManager(self, requestPostsWithCount: 0, parameters: parameters) { response, error in
			if let error = error {
				DispatchQueue.main.async {
					self.delegate?.dataManager(self, didEncounterError: error as NSError)
					self.loadingTop = false
				}
			} else {
				self.postParseQueue.async {
					let posts = { () -> [Post] in
						if let postsKey = self.delegate?.dataManagerPostsJSONKey(self) {
							return JSON(response)[postsKey].array?.map { Post.from($0.dictionaryObject! as NSDictionary) }.flatMap { $0 } ?? []
						} else {
							return JSON(response).array?.map { Post.from($0.dictionaryObject! as NSDictionary) }.flatMap { $0 } ?? []
						}
					}()

					DispatchQueue.main.async {
						self.processPosts(posts, width: width)
						DispatchQueue.main.async {
							var indexSet: IndexSet?
							if self.topID != nil {
								// swiftlint:disable legacy_constructor
								indexSet = IndexSet(integersIn: NSMakeRange(0, posts.count).toRange()!)
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

	open func loadMore(_ width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		guard let posts = posts, let cursor = cursor else {
			return
		}

		let parameters = ["before_id" : "\(cursor)", "reblog_info" : "true"]

		loadingBottom = true
		delegate?.dataManager(self, requestPostsWithCount: posts.count, parameters: parameters as [String : AnyObject]) { response, error in
			if let error = error {
				DispatchQueue.main.async {
					self.delegate?.dataManager(self, didEncounterError: error as NSError)
					self.loadingBottom = false
				}
			} else {
				self.postParseQueue.async {
					let posts = { () -> [Post] in
						if let postsKey = self.delegate?.dataManagerPostsJSONKey(self) {
							return JSON(response)[postsKey].array?.map { Post.from($0.dictionaryObject! as NSDictionary) }.flatMap { $0 } ?? []
						} else {
							return JSON(response).array?.map { Post.from($0.dictionaryObject! as NSDictionary) }.flatMap { $0 } ?? []
						}
					}()

					DispatchQueue.main.async {
						self.processPosts(posts, width: width)
						DispatchQueue.main.async {
							let indexSet = NSMutableIndexSet()
							for row in self.posts.count..<(self.posts.count + posts.count) {
								indexSet.add(row)
							}

							self.delegate?.dataManagerDidReload(self, indexSet: indexSet as IndexSet) {
								self.posts.append(contentsOf: posts)
								self.cursor = posts.last?.id
							}
						}
					}
				}
			}
		}
	}

	open func toggleLikeForPostAtIndex(_ index: Int) {
		var post = posts[index]

		if post.liked {
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

	fileprivate func processPosts(_ posts: [Post], width: CGFloat) {
		for post in posts {
			heightComputationQueue.addOperation() {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.heightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight { height in
					self.heightCalculators[post.id] = nil
					self.postHeightCache.setBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			heightComputationQueue.addOperation() {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.secondaryHeightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight(true) { height in
					self.secondaryHeightCalculators[post.id] = nil
					self.postHeightCache.setSecondaryBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			for (index, _) in post.trailData.enumerated() {
				heightComputationQueue.addOperation() { height in
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
