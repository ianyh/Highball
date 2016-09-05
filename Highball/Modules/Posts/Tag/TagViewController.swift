//
//  TagViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit

public final class TagViewController: PostsViewController {
	public init(tag: String, postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		navigationItem.title = tag
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
