//
//  PostPhotoCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/18/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import FLAnimatedImage
import Foundation

public struct AnimatedImageCache {
	fileprivate static var animatedImageCache = NSCache<NSString, FLAnimatedImage>()

	public static func setAnimatedImage(_ animatedImage: FLAnimatedImage?, forKey key: String) {
		if let image = animatedImage {
			animatedImageCache.setObject(image, forKey: key as NSString)
		}
	}

	public static func animatedImageForKey(_ key: String) -> FLAnimatedImage? {
		return animatedImageCache.object(forKey: key as NSString)
	}

	public static func clearCache() {
		animatedImageCache.removeAllObjects()
	}
}
