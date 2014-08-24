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

    func url() -> (NSURL!) {
        if let url = self.json["original_size"]["url"].string {
            return NSURL(string: url)
        }
        NSException(name: "PostPhoto without url", reason: nil, userInfo: nil).raise()
        return nil
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
