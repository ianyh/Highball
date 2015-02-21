//
//  BlogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit

class BlogViewController: PostsViewController {
    private let blogName: String!

    required init(blogName: String) {
        self.blogName = blogName
        super.init()
        self.navigationItem.title = self.blogName
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = nil
    }

    override func postsFromJSON(json: JSON) -> Array<Post> {
        if let postsJSON = json["posts"].array {
            return postsJSON.map { (post) -> (Post) in
                return Post(json: post)
            }
        }
        return []
    }
    
    override func requestPosts(parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        TMAPIClient.sharedInstance().posts(self.blogName, type: "", parameters: parameters, callback: callback)
    }
    
    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }
}
