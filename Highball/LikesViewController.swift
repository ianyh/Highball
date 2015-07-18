//
//  LikesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import SwiftyJSON
import TMTumblrSDK

class LikesViewController: PostsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Likes"
    }

    override func postsFromJSON(json: JSON) -> Array<Post> {
        if let postsJSON = json["liked_posts"].array {
            return postsJSON.map { (post) -> (Post) in
                return Post(json: post)
            }
        }
        return []
    }

    override func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        var mutableDictionary = parameters
        mutableDictionary["offset"] = postCount
        TMAPIClient.sharedInstance().likes(mutableDictionary, callback: callback)
    }

    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }
}
