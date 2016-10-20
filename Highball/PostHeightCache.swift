//
//  PostHeightCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

open class PostHeightCache {
	fileprivate var bodyHeightCache: [Int: CGFloat] = [:]
	fileprivate var secondaryBodyHeightCache: [Int: CGFloat] = [:]
	fileprivate var bodiesHeightCache: [String: CGFloat] = [:]
	fileprivate var bodiesComponentsHeightCache: [String: [String: CGFloat]] = [:]

	public init() {

	}

	open func resetCache() {
		bodyHeightCache.removeAll()
		secondaryBodyHeightCache.removeAll()
		bodiesHeightCache.removeAll()
	}

	open func setBodyHeight(_ height: CGFloat?, forPost post: Post) {
		bodyHeightCache[post.id] = height
	}

	open func bodyHeightForPost(_ post: Post) -> CGFloat? {
		return bodyHeightCache[post.id]
	}

	open func setSecondaryBodyHeight(_ height: CGFloat?, forPost post: Post) {
		secondaryBodyHeightCache[post.id] = height
	}

	open func secondaryBodyHeightForPost(_ post: Post) -> CGFloat? {
		return secondaryBodyHeightCache[post.id]
	}

	open func setBodyHeight(_ height: CGFloat?, forPost post: Post, atIndex index: Int) {
		let key = "\(post.id):\(index)"
		bodiesHeightCache[key] = height
	}

	open func setBodyComponentHeight(_ height: CGFloat, forPost post: Post, atIndex index: Int, withKey key: String) {
		let postKey = "\(post.id):\(index)"
		if bodiesComponentsHeightCache[postKey] != nil {
			bodiesComponentsHeightCache[postKey]![key] = height
		} else {
			bodiesComponentsHeightCache[postKey] = [key: height]
		}
	}

	open func bodyComponentHeightForPost(_ post: Post, atIndex index: Int, withKey key: String) -> CGFloat? {
		let postKey = "\(post.id):\(index)"
		return bodiesComponentsHeightCache[postKey]?[key]
	}

	open func bodyHeight(_ post: Post, atIndex index: Int) -> CGFloat? {
		let key = "\(post.id):\(index)"
		var height = bodiesHeightCache[key] ?? 0
		let componentHeights = bodiesComponentsHeightCache[key] ?? [:]
		height += componentHeights.values.reduce(0, +)
		return height
	}
}
