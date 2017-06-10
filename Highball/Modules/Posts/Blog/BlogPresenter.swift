//
//  BlogPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

class BlogPresenter: PostsPresenter {
	weak var view: PostsView?
	var dataManager: PostsDataManager?
	var loadingCompletion: (() -> Void)?

	fileprivate let blogName: String

	init(blogName: String) {
		self.blogName = blogName
	}

	func follow() {
		TMAPIClient.sharedInstance().follow(blogName) { _, error in
			if error == nil {
				self.view?.presentMessage("Followed", message: "Successfully followed \(self.blogName)!")
			} else {
				self.view?.presentMessage("Follow Failed", message: "Tried to follow \(self.blogName), but failed.")
			}
		}
	}

	func unfollow() {
		TMAPIClient.sharedInstance().unfollow(blogName) { _, error in
			if error == nil {
				self.view?.presentMessage("Unfollowed", message: "Successfully unfollowed \(self.blogName)!")
			} else {
				self.view?.presentMessage("Unfollow Failed", message: "Tried to unfollow \(self.blogName), but failed.")
			}
		}
	}
}

extension BlogPresenter {
	func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : Any], callback: @escaping TMAPICallback) {
		TMAPIClient.sharedInstance().posts(blogName, type: "", parameters: parameters, callback: callback)
	}

	func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String? {
		return "posts"
	}
}
