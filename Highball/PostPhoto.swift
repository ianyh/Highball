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
    let sizes: Array<JSON>
    let widthToHeightRatio: Float?

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
        var sizes = [json["original_size"]]
        sizes.extend(json["alt_sizes"].arrayValue.sorted({ $0["width"].int! > $1["width"].int! }))
        self.sizes = sizes
        if let width = json["original_size"]["width"].float {
            if let height = json["original_size"]["height"].float {
                self.widthToHeightRatio = width / height
            }
        }
    }

    func urlWithWidth(width: CGFloat) -> NSURL {
        let largerSizes = self.sizes.filter {
            if let sizeWidth = $0["width"].int {
                return CGFloat(sizeWidth) > width
            }
            return false
        }
        if let smallestFittedSize = largerSizes.last {
            return NSURL(string: smallestFittedSize["url"].string!)!
        } else {
            return NSURL(string: self.sizes.first!["url"].stringValue)!
        }
    }
}
