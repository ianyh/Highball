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
	internal private(set) var bodiesHeightCache: [String: CGFloat] = [:]

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

	func setBodyHeight(height: CGFloat?, forPost post: Post, atIndex index: Int) {
		let key = "\(post.id):\(index)"
		bodiesHeightCache[key] = height
	}

	func bodyHeight(post: Post, atIndex index: Int) -> CGFloat? {
		let key = "\(post.id):\(index)"
		return bodiesHeightCache[key]
	}
}
