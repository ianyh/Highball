//
//  PostPhoto.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class PostPhoto {
    private let json: JSON!

    lazy var width: CGFloat = {
        if let width = self.json["original_size"]["width"].int {
            return CGFloat(width)
        }
        return 0
    }()

    lazy var height: CGFloat = {
        if let height = self.json["original_size"]["height"].int {
            return CGFloat(height)
        }
        return 0
    }()

    required init(json: JSON!) {
        self.json = json
    }

    func urlWithWidth(width: CGFloat) -> (NSURL!) {
        let originalSize = self.json["original_size"]
        let alternateSizes = self.json["alt_sizes"].array!.sorted({ $0["width"].int! > $1["width"].int! })

        var smallestFittedSize = self.json["original_size"]
        for size in alternateSizes {
            if CGFloat(size["width"].int!) < width {
                break
            }

            smallestFittedSize = size
        }

        return NSURL(string: smallestFittedSize["url"].string!)
    }
}
