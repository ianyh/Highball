//
//  Post.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

enum ReblogType {
    case Reblog
    case Queue
}

class Post {
    let id: Int!
    let type: String!
    let blogName: String!
    let reblogKey: String!
    let shortURLString: String!
    var liked: Bool!

    private let json: JSON!

    required init(json: JSON!) {
        self.json = json
        self.id = json["id"].int!
        self.type = json["type"].string!
        self.blogName = json["blog_name"].string!
        self.reblogKey = json["reblog_key"].string!
        self.shortURLString = json["short_url"].string!
        self.liked = json["liked"].bool!
    }

    func photos() -> (Array<PostPhoto>) {
        if let photos = self.json["photos"].array {
            return photos.map { (photoJSON: JSON!) -> (PostPhoto) in
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
            return entries.map { (entryJSON: JSON) -> (PostDialogueEntry) in
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
                let sortedPlayers = players.sorted({ $0["width"].int! > $1["width"].int! })
                if countElements(sortedPlayers) > 0 {
                    let screenWidth = UIScreen.mainScreen().bounds.size.width
                    var finalPlayer: String? = sortedPlayers.first!["embed_code"].string!
                    for player in sortedPlayers {
                        if player["width"].int! < Int(screenWidth) {
                            break
                        }
                        finalPlayer = player["embed_code"].string!
                    }
                    bodyString = finalPlayer
                }
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
