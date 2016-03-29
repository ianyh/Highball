//
//  TagViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import SwiftyJSON
import TMTumblrSDK

final class TagViewController: PostsViewController {
	private let tag: String!

	init(tag: String) {
		self.tag = tag.substringFromIndex(tag.startIndex.advancedBy(1))
		super.init()
		navigationItem.title = tag
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func postsFromJSON(json: JSON) -> Array<Post> {
		guard let postsJSON = json.array else {
			return []
		}

		return postsJSON.map { (post) -> (Post) in
			return Post(json: post)
		}
	}

	override func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
		var mutableParameters = parameters
		if let lastPost = dataManager.posts?.last {
			mutableParameters["before"] = "\(lastPost.timestamp)"
		}
		TMAPIClient.sharedInstance().tagged(self.tag, parameters: mutableParameters, callback: callback)
	}
}
