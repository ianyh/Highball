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
    private let json: JSON!

    var id: Int {
        get {
            return self.json["id"].int!
        }
    }
    var type: String {
        get {
            return self.json["type"].string!
        }
    }
    var blogName: String {
        get {
            return self.json["blog_name"].string!
        }
    }
    var reblogKey: String {
        get {
            return self.json["reblog_key"].string!
        }
    }
    var shortURLString: String {
        get {
            return self.json["short_url"].string!
        }
    }

    var photos: Array<PostPhoto> {
        get {
            if let photos = self.json["photos"].array {
                return photos.map { (photoJSON: JSON!) -> (PostPhoto) in
                    return PostPhoto(json: photoJSON)
                }
            }
            return []
        }
    }

    var layoutRows: Array<Int> {
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

    var dialogueEntries: Array<PostDialogueEntry> {
        get {
            var dialogueEntries = Array<PostDialogueEntry>()
            if let entries = self.json["dialogue"].array {
                return entries.map { (entryJSON: JSON) -> (PostDialogueEntry) in
                    return PostDialogueEntry(json: entryJSON)
                }
            }
            return dialogueEntries
        }
    }

    var body: String? {
        get {
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
    }

    var secondaryBody: String? {
        get {
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
    }

    var asker: String? {
        get {
            return self.json["asking_name"].string
        }
    }

    var question: String? {
        get {
            return self.json["question"].string
        }
    }

    var title: String? {
        get {
            return self.json["title"].string
        }
    }

    var urlString: String? {
        get {
            return self.json["url"].string
        }
    }

    var liked = false

    required init(json: JSON!) {
        self.json = json
        self.liked = json["liked"].bool!
    }

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
