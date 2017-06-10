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

protocol PostsDataManagerDelegate: class {
	func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String: Any], callback: @escaping TMAPICallback)
	func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String?
	func dataManagerDidReload(_ dataManager: PostsDataManager, indexSet: IndexSet?, completion: @escaping () -> Void)
	func dataManagerDidComputeHeight(_ dataManager: PostsDataManager)
	func dataManager(_ dataManager: PostsDataManager, didEncounterError error: Error)
}

final class PostsDataManager {
	private let heightComputationQueue: OperationQueue!
	private let postParseQueue = DispatchQueue(label: "postParseQueue", attributes: [])

	private let postHeightCache: PostHeightCache
	private weak var delegate: PostsDataManagerDelegate?

	private var heightCalculators: [Int: HeightCalculator] = [:]
	private var secondaryHeightCalculators: [Int: HeightCalculator] = [:]
	private var bodyHeightCalculators: [String: HeightCalculator] = [:]

	var posts: [Post]!
	var topID: Int?
	var cursor: Int?

	var loadingTop = false
	var loadingBottom = false
	var lastPoint: CGPoint?

	var hasPosts: Bool {
		return self.posts != nil && posts.count > 0
	}
	var computingHeights: Bool {
		return heightComputationQueue.operationCount > 0 ||
			heightCalculators.count > 0 ||
			secondaryHeightCalculators.count > 0 ||
			bodyHeightCalculators.count > 0
	}

	init(postHeightCache: PostHeightCache, delegate: PostsDataManagerDelegate) {
		self.postHeightCache = postHeightCache
		self.delegate = delegate
		self.heightComputationQueue = OperationQueue()
		self.heightComputationQueue.underlyingQueue = DispatchQueue.main
	}

	func loadTop(_ width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		loadingTop = true

		var reloadCompletion: ([Post]) -> Void
		var parameters: [String: Any]

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
			guard let response = response, error == nil else {
				DispatchQueue.main.async {
					self.delegate?.dataManager(self, didEncounterError: error!)
					self.loadingTop = false
				}
				return
			}

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

	func loadMore(_ width: CGFloat) {
		if loadingTop || loadingBottom {
			return
		}

		guard let posts = posts, let cursor = cursor else {
			return
		}

		let parameters = ["before_id": "\(cursor)", "reblog_info": "true"]

		loadingBottom = true
		delegate?.dataManager(self, requestPostsWithCount: posts.count, parameters: parameters as [String : Any]) { response, error in
			guard let response = response, error == nil else {
				DispatchQueue.main.async {
					self.delegate?.dataManager(self, didEncounterError: error!)
					self.loadingBottom = false
				}
				return
			}

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

	func toggleLikeForPostAtIndex(_ index: Int) {
		var post = posts[index]

		if post.liked {
			TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey) { (_, error) in
				if let error = error {
					print(error)
				} else {
					post.liked = false
					self.posts[index] = post
				}
			}
		} else {
			TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey) { (_, error) in
				if let error = error {
					print(error)
				} else {
					post.liked = true
					self.posts[index] = post
				}
			}
		}
	}

	private func processPosts(_ posts: [Post], width: CGFloat) {
		for post in posts {
			heightComputationQueue.addOperation {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.heightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight { height in
					self.heightCalculators[post.id] = nil
					self.postHeightCache.setBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			heightComputationQueue.addOperation {
				let heightCalculator = HeightCalculator(post: post, width: width)

				self.secondaryHeightCalculators[post.id] = heightCalculator

				heightCalculator.calculateHeight(true) { height in
					self.secondaryHeightCalculators[post.id] = nil
					self.postHeightCache.setSecondaryBodyHeight(height, forPost: post)
					self.delegate?.dataManagerDidComputeHeight(self)
				}
			}
			for index in post.trailData.indices {
				heightComputationQueue.addOperation { height in
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
