//
//  LikesPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

class LikesPresenter: PostsPresenter {
	weak var view: PostsView?
	var dataManager: PostsDataManager?
	var loadingCompletion: (() -> Void)?

	func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : Any], callback: @escaping TMAPICallback) {
		var mutableParameters = parameters
//		mutableParameters["offset"] = postCount as AnyObject?
		TMAPIClient.sharedInstance().likes(mutableParameters, callback: callback)
	}

	func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String? {
		return "liked_posts"
	}
}
