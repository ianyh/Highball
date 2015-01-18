//
//  PostPhotoCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/18/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Foundation

struct AnimatedImageCache {
    private static var animatedImageCache = Dictionary<String, FLAnimatedImage>()

    static func setAnimatedImage(animatedImage: FLAnimatedImage, forKey key: String) {
        self.animatedImageCache[key] = animatedImage
    }

    static func animatedImageForKey(key: String) -> FLAnimatedImage? {
        return self.animatedImageCache[key]
    }
}
