//
//  LikesPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

open class LikesPresenter: PostsPresenter {
	open weak var view: PostsView?
	open var dataManager: PostsDataManager?
	open var loadingCompletion: (() -> Void)?

	public func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: @escaping TMAPICallback) {
		var mutableParameters = parameters
		mutableParameters["offset"] = postCount as AnyObject?
		TMAPIClient.sharedInstance().likes(mutableParameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String? {
		return "liked_posts"
	}
}
