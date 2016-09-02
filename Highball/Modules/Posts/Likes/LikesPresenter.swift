//
//  LikesPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

public class LikesPresenter: PostsPresenter {
	public weak var view: PostsView?
	public var dataManager: PostsDataManager?
	public var loadingCompletion: (() -> ())?
}

public extension LikesPresenter {
	public func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: TMAPICallback) {
		var mutableParameters = parameters
		mutableParameters["offset"] = postCount
		TMAPIClient.sharedInstance().likes(mutableParameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(dataManager: PostsDataManager) -> String? {
		return "liked_posts"
	}
}
