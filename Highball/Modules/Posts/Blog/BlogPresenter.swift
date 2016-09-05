//
//  BlogPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

public class BlogPresenter: PostsPresenter {
	public weak var view: PostsView?
	public var dataManager: PostsDataManager?
	public var loadingCompletion: (() -> ())?

	private let blogName: String

	public init(blogName: String) {
		self.blogName = blogName
	}

	public func follow() {
		TMAPIClient.sharedInstance().follow(blogName) { result, error in
			if error == nil {
				self.view?.presentMessage("Followed", message: "Successfully followed \(self.blogName)!")
			} else {
				self.view?.presentMessage("Follow Failed", message: "Tried to follow \(self.blogName), but failed.")
			}
		}
	}

	public func unfollow() {
		TMAPIClient.sharedInstance().unfollow(blogName) { result, error in
			if error == nil {
				self.view?.presentMessage("Unfollowed", message: "Successfully unfollowed \(self.blogName)!")
			} else {
				self.view?.presentMessage("Unfollow Failed", message: "Tried to unfollow \(self.blogName), but failed.")
			}
		}
	}
}

public extension BlogPresenter {
	public func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: TMAPICallback) {
		TMAPIClient.sharedInstance().posts(blogName, type: "", parameters: parameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(dataManager: PostsDataManager) -> String? {
		return "posts"
	}
}
