//
//  FollowedBlogsDataManager.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/24/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import SwiftyJSON
import TMTumblrSDK
import UIKit

protocol FollowedBlogsDataManagerDelegate: class {
	func dataManagerDidReload(_ dataManager: FollowedBlogsDataManager, indexSet: IndexSet?)
	func dataManager(_ dataManager: FollowedBlogsDataManager, didEncounterError error: Error)
}

class FollowedBlogsDataManager {
	fileprivate let delegate: FollowedBlogsDataManagerDelegate
	fileprivate(set) var blogs: [Blog] = []
	fileprivate var blogCount: Int?
	fileprivate(set) var loading = false

	init(delegate: FollowedBlogsDataManagerDelegate) {
		self.delegate = delegate
	}

	func load() {
		if loading {
			return
		}

		loading = true
		blogs = []

		loadMore()
	}

	fileprivate func loadMore() {
		if let blogCount = blogCount, blogs.count >= blogCount {
			delegate.dataManagerDidReload(self, indexSet: nil)
			return
		}

		TMAPIClient.sharedInstance().following(["offset": "\(blogs.count)"]) { response, error in
			guard let response = response, error == nil else {
				DispatchQueue.main.async {
					self.loading = false
					self.delegate.dataManager(self, didEncounterError: error!)
				}
				return
			}

			DispatchQueue.main.async {
				let moreBlogs = JSON(response)["blogs"].array!.map { Blog.from($0.dictionaryObject! as NSDictionary)! }
				self.blogCount = JSON(response)["total_blogs"].int
				self.blogs.append(contentsOf: moreBlogs)
				self.loadMore()
			}
		}
	}
}
