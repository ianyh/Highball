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

class LikesViewController: PostsViewController {
    override init() {
        super.init()

        navigationItem.title = "Likes"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func postsFromJSON(json: JSON) -> Array<Post> {
        if let postsJSON = json["liked_posts"].array {
            return postsJSON.map { (post) -> (Post) in
                return Post(json: post)
            }
        }
        return []
    }

    override func requestPosts(postCount: Int, var parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        parameters["offset"] = postCount
        TMAPIClient.sharedInstance().likes(parameters, callback: callback)
    }

    override func reblogBlogName() -> String {
        return AccountsService.account.blog.name
    }
}
