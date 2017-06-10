//
//  PostPhotoCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/18/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import FLAnimatedImage
import Foundation

struct AnimatedImageCache {
	fileprivate static var animatedImageCache = NSCache<NSString, FLAnimatedImage>()

	static func setAnimatedImage(_ animatedImage: FLAnimatedImage?, forKey key: String) {
		if let image = animatedImage {
			animatedImageCache.setObject(image, forKey: key as NSString)
		}
	}

	static func animatedImageForKey(_ key: String) -> FLAnimatedImage? {
		return animatedImageCache.object(forKey: key as NSString)
	}

	static func clearCache() {
		animatedImageCache.removeAllObjects()
	}
}
