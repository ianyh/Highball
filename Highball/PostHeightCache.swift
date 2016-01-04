//
//  PostHeightCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

class PostHeightCache {
	private var bodyHeightCache: [Int: CGFloat] = [:]
	private var secondaryBodyHeightCache: [Int: CGFloat] = [:]

	init() {

	}

	func setBodyHeight(height: CGFloat?, forPost post: Post) {
		bodyHeightCache[post.id] = height
	}

	func bodyHeightForPost(post: Post) -> CGFloat? {
		return bodyHeightCache[post.id]
	}

	func setSecondaryBodyHeight(height: CGFloat?, forPost post: Post) {
		secondaryBodyHeightCache[post.id] = height
	}

	func secondaryBodyHeightForPost(post: Post) -> CGFloat? {
		return secondaryBodyHeightCache[post.id]
	}
}
