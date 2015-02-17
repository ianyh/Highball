//
//  PostPhotoCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/18/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Foundation

struct AnimatedImageCache {
    private static var animatedImageCache = NSCache()

    static func setAnimatedImage(animatedImage: FLAnimatedImage?, forKey key: String) {
        if let image = animatedImage {
            self.animatedImageCache.setObject(image, forKey: key)
        }
    }

    static func animatedImageForKey(key: String) -> FLAnimatedImage? {
        return self.animatedImageCache.objectForKey(key) as? FLAnimatedImage
    }

    static func clearCache() {
        self.animatedImageCache.removeAllObjects()
    }
}
