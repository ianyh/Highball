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
    private let json: JSON
    let id: Int
    let type: String
    let blogName: String
    let rebloggedBlogName: String?
    let reblogKey: String
    let timestamp: Int
    let shortURLString: String
    let tags: Array<String>
    let photos: Array<PostPhoto>
    let layoutRows: Array<Int>
    let dialogueEntries: Array<PostDialogueEntry>
    let body: String?
    let secondaryBody: String?
    let asker: String?
    let question: String?
    let title: String?
    let urlString: String?

    required init(json: JSON!) {
        self.json = json
        self.id = json["id"].int!
        self.type = json["type"].string!
        self.blogName = json["blog_name"].string!
        self.rebloggedBlogName = json["reblogged_from_name"].string
        self.reblogKey = json["reblog_key"].string!
        self.timestamp = json["timestamp"].int!
        self.shortURLString = json["short_url"].string!
        if let tagsJSON = json["tags"].array {
            self.tags = tagsJSON.map { tag in
                return "#\(tag)"
            }
        } else {
            self.tags = []
        }
        if let photosJSON = self.json["photos"].array {
            self.photos = photosJSON.map { photoJSON in
                return PostPhoto(json: photoJSON)
            }
        } else {
            self.photos = []
        }
        if let layoutString = self.json["photoset_layout"].string {
            var photosetLayoutRows = Array<Int>()
            for character in layoutString {
                photosetLayoutRows.insert("\(character)".toInt()!, atIndex: 0)
            }
            self.layoutRows = photosetLayoutRows
        } else {
            self.layoutRows = [1]
        }
        if let entriesJSON = self.json["dialogue"].array {
            self.dialogueEntries = entriesJSON.map { entryJSON in
                return PostDialogueEntry(json: entryJSON)
            }
        } else {
            self.dialogueEntries = []
        }
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
        self.body = nil
        if let string = bodyString {
            if countElements(string) > 0 {
                self.body = string
            }
        }
        bodyString = nil
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
        self.secondaryBody = nil
        if let string = bodyString {
            if countElements(string) > 0 {
                self.secondaryBody = string
            }
        }
        self.asker = json["asking_name"].string
        self.question = json["question"].string
        self.title = json["title"].string
        self.urlString = json["url"].string
        self.liked = json["liked"].bool!
    }

    var liked = false

    func htmlBodyWithWidth(width: CGFloat) -> (String?) {
        return self.body?.htmlStringWithTumblrStyle(width)
    }

    func htmlSecondaryBodyWithWidth(width: CGFloat) -> (String?) {
        var stringToStyle: String?
        if let secondaryBody = self.secondaryBody {
            switch self.type {
            case "quote":
                stringToStyle = "<table><tr><td>-&nbsp;</td><td>\(secondaryBody)</td></tr></table>"
            default:
                stringToStyle = secondaryBody
            }
        }

        return stringToStyle?.htmlStringWithTumblrStyle(width)
    }
}
