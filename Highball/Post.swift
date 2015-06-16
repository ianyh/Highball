//
//  Post.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftyJSON

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
    let thumbnailURLString: String?
    let permalinkURLString: String?
    let videoType: String?
    let videoURLString: String?
    let videoWidth: Float?
    let videoHeight: Float?
    var liked = false

    var cachedVideoPlayer: AVPlayer?

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
                photosetLayoutRows.append("\(character)".toInt()!)
            }
            self.layoutRows = photosetLayoutRows
        } else if self.photos.count == 0 {
            self.layoutRows = []
        } else if self.photos.count % 2 == 0 {
            var layoutRows = Array<Int>()
            for i in 0...self.photos.count/2-1 {
                layoutRows.append(2)
            }
            self.layoutRows = layoutRows
        } else if self.photos.count % 3 == 0 {
            var layoutRows = Array<Int>()
            for i in 0...self.photos.count/3-1 {
                layoutRows.append(3)
            }
            self.layoutRows = layoutRows
        } else {
            var layoutRows = Array<Int>()
            for i in 0...self.photos.count-1 {
                layoutRows.append(1)
            }
            self.layoutRows = layoutRows
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
        if let string = bodyString {
            if count(string) > 0 {
                self.body = string
            } else {
                self.body = nil
            }
        } else {
            self.body = nil
        }
        bodyString = nil
        switch self.type {
        case "quote":
            bodyString = self.json["source"].string
        case "audio":
            bodyString = self.json["player"].string
        default:
            bodyString = nil
        }
        if let string = bodyString {
            if count(string) > 0 {
                self.secondaryBody = string
            } else {
                self.secondaryBody = nil
            }
        } else {
            self.secondaryBody = nil
        }
        self.asker = json["asking_name"].string
        self.question = json["question"].string
        self.title = json["title"].string
        self.urlString = json["url"].string
        self.thumbnailURLString = json["thumbnail_url"].string
        self.permalinkURLString = json["permalink_url"].string
        self.videoType = json["video_type"].string
        self.videoURLString = json["video_url"].string
        self.videoWidth = json["thumbnail_width"].float
        self.videoHeight = json["thumbnail_height"].float
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

    func videoURL() -> NSURL? {
        if self.type != "video" {
            return nil
        }

        if let videoType = self.videoType {
            switch videoType {
            case "vine":
                if let permalinkURLString = self.permalinkURLString {
                    if let permalinkURL = NSURL(string: permalinkURLString) {
                        let document = NSString(data: NSData(contentsOfURL: permalinkURL)!, encoding: NSASCIIStringEncoding) as? String
                        if let document = document {
                            let metaStringRange = document.rangeOfString("twitter:player:stream.*?content=\".*?\"", options: NSStringCompareOptions.RegularExpressionSearch)
                            if let metaStringRange = metaStringRange {
                                let metaString = document.substringWithRange(metaStringRange)
                                var urlStringRange = metaString.rangeOfString("http.*?\"", options: NSStringCompareOptions.RegularExpressionSearch)
                                urlStringRange?.endIndex--
                                if let urlStringRange = urlStringRange {
                                    let urlString = metaString.substringWithRange(urlStringRange)
                                    return NSURL(string: urlString)
                                }
                            }
                        }
                    }
                }
            case "youtube":
                if let permalinkURLString = self.permalinkURLString {
                    return NSURL(string: permalinkURLString)
                }
            default:
                if let videoURLString = self.videoURLString {
                    return NSURL(string: videoURLString)
                }
            }
        }

        return nil
    }

    func videoHeightWidthWidth(width: CGFloat) -> CGFloat? {
        if self.type != "video" {
            return nil
        }

        if let videoWidth = self.videoWidth {
            if let videoHeight = self.videoHeight {
                return floor(CGFloat(videoHeight / videoWidth) * width)
            }
        }

        return nil
    }
}
