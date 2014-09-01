//
//  PostPhoto.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class PostPhoto {
    let json: JSONValue!

    required init(json: JSONValue!) {
        self.json = json
    }

    func urlWithWidth(width: CGFloat) -> (NSURL!) {
        let originalSize = self.json["original_size"]
        let alternateSizes = self.json["alt_sizes"].array!.sorted({ $0["width"].integer! > $1["width"].integer! })

        var smallestFittedSize = self.json["original_size"]
        for size in alternateSizes {
            if CGFloat(size["width"].integer!) < width {
                break
            }

            smallestFittedSize = size
        }

        return NSURL(string: smallestFittedSize["url"].string!)
    }

    func width() -> (CGFloat) {
        if let width = self.json["original_size"]["width"].integer {
            return CGFloat(width)
        }
        return 0
    }

    func height() -> (CGFloat) {
        if let height = self.json["original_size"]["height"].integer {
            return CGFloat(height)
        }
        return 0
    }
}
