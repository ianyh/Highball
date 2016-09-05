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
	public override init(postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		navigationItem.title = "Likes"
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
