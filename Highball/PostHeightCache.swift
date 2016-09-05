//
//  PostHeightCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

public class PostHeightCache {
	private var bodyHeightCache: [Int: CGFloat] = [:]
	private var secondaryBodyHeightCache: [Int: CGFloat] = [:]
	private var bodiesHeightCache: [String: CGFloat] = [:]
	private var bodiesComponentsHeightCache: [String: [String: CGFloat]] = [:]

	public init() {

	}

	public func resetCache() {
		bodyHeightCache.removeAll()
		secondaryBodyHeightCache.removeAll()
		bodiesHeightCache.removeAll()
	}

	public func setBodyHeight(height: CGFloat?, forPost post: Post) {
		bodyHeightCache[post.id] = height
	}

	public func bodyHeightForPost(post: Post) -> CGFloat? {
		return bodyHeightCache[post.id]
	}

	public func setSecondaryBodyHeight(height: CGFloat?, forPost post: Post) {
		secondaryBodyHeightCache[post.id] = height
	}

	public func secondaryBodyHeightForPost(post: Post) -> CGFloat? {
		return secondaryBodyHeightCache[post.id]
	}

	public func setBodyHeight(height: CGFloat?, forPost post: Post, atIndex index: Int) {
		let key = "\(post.id):\(index)"
		bodiesHeightCache[key] = height
	}

	public func setBodyComponentHeight(height: CGFloat, forPost post: Post, atIndex index: Int, withKey key: String) {
		let postKey = "\(post.id):\(index)"
		if bodiesComponentsHeightCache[postKey] != nil {
			bodiesComponentsHeightCache[postKey]![key] = height
		} else {
			bodiesComponentsHeightCache[postKey] = [key: height]
		}
	}

	public func bodyComponentHeightForPost(post: Post, atIndex index: Int, withKey key: String) -> CGFloat? {
		let postKey = "\(post.id):\(index)"
		return bodiesComponentsHeightCache[postKey]?[key]
	}

	public func bodyHeight(post: Post, atIndex index: Int) -> CGFloat? {
		let key = "\(post.id):\(index)"
		var height = bodiesHeightCache[key] ?? 0
		let componentHeights = bodiesComponentsHeightCache[key] ?? [:]
		height += componentHeights.values.reduce(0, combine: +)
		return height
	}
}
