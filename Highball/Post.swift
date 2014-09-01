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
            for character in layoutString {
                photosetLayoutRows.insert("\(character)".toInt()!, atIndex: 0)
            }
        } else {
            photosetLayoutRows = [1]
        }
        return photosetLayoutRows
    }

    func dialogueEntries() -> (Array<PostDialogueEntry>) {
        var dialogueEntries = Array<PostDialogueEntry>()
        if let entries = self.json["dialogue"].array {
            return entries.map { (entryJSON: JSONValue!) -> (PostDialogueEntry) in
                return PostDialogueEntry(json: entryJSON)
            }
        }
        return dialogueEntries
    }

    func body() -> (String?) {
        var bodyString: String?
        switch self.type {
        case "photo":
            bodyString = self.json["caption"].string
        case "text":
            bodyString = self.json["body"].string
        case "answer":
            bodyString = self.json["answer"].string
        case "quote":
            bodyString = self.json["text"].string
        case "link":
            bodyString = self.json["description"].string
        case "video":
            bodyString = self.json["caption"].string
        case "audio":
            bodyString = self.json["caption"].string
        default:
            bodyString = nil
        }

        if let string = bodyString {
            if countElements(string) > 0 {
                return string
            }
        }

        return nil
    }

    func htmlBodyWithWidth(width: CGFloat) -> (String?) {
        return self.body()?.htmlStringWithTumblrStyle(width)
    }

    func secondaryBody() -> (String?) {
        var bodyString: String?
        switch self.type {
        case "quote":
            bodyString = self.json["source"].string
        case "video":
            if let players = self.json["player"].array {
                let sortedPlayers = players.sorted({ $0["width"].integer! > $1["width"].integer! })
                let screenWidth = UIScreen.mainScreen().bounds.size.width
                var finalPlayer: String? = nil
                for player in sortedPlayers {
                    finalPlayer = player["embed_code"].string!
                    if player["width"].integer! > Int(screenWidth) {
                        break
                    }
                }
                bodyString = finalPlayer
            }
        case "audio":
            bodyString = self.json["player"].string
        default:
            bodyString = nil
        }

        if let string = bodyString {
            if countElements(string) > 0 {
                return string
            }
        }

        return nil
    }

    func htmlSecondaryBodyWithWidth(width: CGFloat) -> (String?) {
        var stringToStyle: String?
        if let secondaryBody = self.secondaryBody() {
            switch self.type {
            case "quote":
                stringToStyle = "<table><tr><td>-&nbsp;</td><td>\(secondaryBody)</td></tr></table>"
            default:
                stringToStyle = secondaryBody
            }
        }

        return stringToStyle?.htmlStringWithTumblrStyle(width)
    }

    func asker() -> (String?) {
        return self.json["asking_name"].string
    }

    func question() -> (String?) {
        return self.json["question"].string
    }

    func title() -> (String?) {
        return self.json["title"].string
    }

    func urlString() -> (String?) {
        return self.json["url"].string
    }

}
