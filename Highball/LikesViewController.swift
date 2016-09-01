//
//  LikesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import SwiftyJSON
import TMTumblrSDK
import UIKit

public class LikesViewController: PostsViewController {
	public override init() {
		super.init()

		navigationItem.title = "Likes"
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func postsFromJSON(json: JSON) -> Array<Post> {
		guard let postsJSON = json["liked_posts"].array else {
			return []
		}

		return postsJSON.map { Post.from($0.dictionaryObject!) }.flatMap { $0 }
	}

	public override func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
		var mutableParameters = parameters
		mutableParameters["offset"] = postCount
		TMAPIClient.sharedInstance().likes(mutableParameters, callback: callback)
	}
}
