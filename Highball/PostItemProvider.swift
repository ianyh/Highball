//
//  PostItemProvider.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/10/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostItemProvider: UIActivityItemProvider {
    var post: Post!

    override func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        return post.urlString
    }
}
