//
//  PostPhoto.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class PostPhoto {
    private let json: JSON
    let width: CGFloat
    let height: CGFloat
    let originalSize: JSON
    let alternateSizes: Array<JSON>

    required init(json: JSON) {
        self.json = json
        if let width = json["original_size"]["width"].int {
            self.width = CGFloat(width)
        } else {
            self.width = 0
        }
        if let height = json["original_size"]["height"].int {
            self.height = CGFloat(height)
        } else {
            self.height = 0
        }
        self.originalSize = json["original_size"]
        self.alternateSizes = json["alt_sizes"].array!.sorted({ $0["width"].int! > $1["width"].int! })
    }

    func urlWithWidth(width: CGFloat) -> (NSURL!) {
        var smallestFittedSize = self.originalSize
        for size in self.alternateSizes {
            if CGFloat(size["width"].int!) < width {
                break
            }

            smallestFittedSize = size
        }

        return NSURL(string: smallestFittedSize["url"].string!)
    }
}
