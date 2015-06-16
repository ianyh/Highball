//
//  TagViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import SwiftyJSON

class TagViewController: PostsViewController {
    private let tag: String!
    
    required init(tag: String) {
        self.tag = tag.substringFromIndex(advance(tag.startIndex, 1))
        super.init()
        self.navigationItem.title = tag
    }
    
    required override init() {
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
        if let postsJSON = json.array {
            return postsJSON.map { (post) -> (Post) in
                return Post(json: post)
            }
        }
        return []
    }
    
    override func requestPosts(parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
        var modifiedParameters = Dictionary<String, AnyObject>()
        for (key, value) in parameters {
            modifiedParameters[key] = value
        }
        if let posts = self.posts {
            if let lastPost = posts.last {
                modifiedParameters["before"] = "\(lastPost.timestamp)"
            }
        }
        TMAPIClient.sharedInstance().tagged(self.tag, parameters: modifiedParameters, callback: callback)
    }
    
    override func reblogBlogName() -> (String) {
        return AccountsService.account.blog.name
    }
}
