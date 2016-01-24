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

protocol FollowedBlogsDataManagerDelegate {
	func dataManagerDidReload(dataManager: FollowedBlogsDataManager, indexSet: NSIndexSet?)
	func dataManager(dataManager: FollowedBlogsDataManager, didEncounterError error: NSError)
}

class FollowedBlogsDataManager {
	private let delegate: FollowedBlogsDataManagerDelegate
	private(set) var blogs: [Blog] = []
	private var blogCount: Int?
	private(set) var loading = false

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

	private func loadMore() {
		if let blogCount = blogCount where blogs.count >= blogCount {
			delegate.dataManagerDidReload(self, indexSet: nil)
			return
		}

		TMAPIClient.sharedInstance().following(["offset" : "\(blogs.count)"]) { response, error in
			if let error = error {
				dispatch_async(dispatch_get_main_queue()) {
					self.loading = false
					self.delegate.dataManager(self, didEncounterError: error)
				}
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					let moreBlogs = JSON(response)["blogs"].array!.map { Blog(json: $0) }
					self.blogCount = JSON(response)["total_blogs"].int
					self.blogs.appendContentsOf(moreBlogs)
					self.loadMore()
				}
			}
		}
	}
}
