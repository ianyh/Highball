//
//  TagPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

public class TagPresenter: PostsPresenter {
	public weak var view: PostsView?
	public var dataManager: PostsDataManager?
	public var loadingCompletion: (() -> ())?

	private let tag: String

	public init(tag: String) {
		self.tag = tag.substringFromIndex(tag.startIndex.advancedBy(1))
	}
}

public extension TagPresenter {
	public func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: TMAPICallback) {
		var mutableParameters = parameters
		if let lastPost = dataManager.posts?.last {
			mutableParameters["before"] = "\(lastPost.timestamp)"
		}
		TMAPIClient.sharedInstance().tagged(tag, parameters: mutableParameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(dataManager: PostsDataManager) -> String? {
		return nil
	}
}
