//
//  Post.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class Post {
    var json: JSONValue!
    var id: Int!
    var type: String!
    var blogName: String!

    required init(json: JSONValue!) {
        self.json = json
        self.id = json["id"].integer!
        self.type = json["type"].string!
        self.blogName = json["blog_name"].string!
    }

    func photos() -> (Array<PostPhoto>) {
        if let photos = self.json["photos"].array {
            return photos.map { (photoJSON: JSONValue!) -> (PostPhoto) in
                return PostPhoto(json: photoJSON)
            }
        }
        return []
    }

    func layoutRows() -> (Array<Int>) {
        var photosetLayoutRows = Array<Int>()
        if let layoutString = self.json["photoset_layout"].string {
            for character in self.json["photoset_layout"].string! {
                photosetLayoutRows.insert("\(character)".toInt()!, atIndex: 0)
            }
        }
        return photosetLayoutRows
    }

    func body() -> (String?) {
        if let caption = self.json["caption"].string {
            return caption
        } else if let body = self.json["body"].string {
            return body
        }
        return nil
    }
}
