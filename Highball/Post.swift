//
//  Post.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

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
	let urlString: String
	let shortURLString: String
	let tags: [String]
	let photos: [PostPhoto]
	let layoutRows: PhotosetLayoutRows
	let dialogueEntries: [PostDialogueEntry]
	let body: String?
	let secondaryBody: String?
	let asker: String?
	let question: String?
	let title: String?
	let thumbnailURLString: String?
	let permalinkURLString: String?
	let videoType: String?
	let videoURLString: String?
	let videoWidth: Float?
	let videoHeight: Float?
	var liked = false

	let bodies: [String]
	let usernames: [String]

	init(json: JSON) {
		self.json = json
		self.id = json["id"].int!
		self.type = json["type"].string!
		self.blogName = json["blog_name"].string!
		self.rebloggedBlogName = json["reblogged_from_name"].string
		self.reblogKey = json["reblog_key"].string!
		self.timestamp = json["timestamp"].int!
		self.urlString = json["post_url"].string!
		self.shortURLString = json["short_url"].string!
		self.tags = json["tags"].array?.map { "#\($0)" } ?? []
		self.photos = json["photos"].array?.map { PostPhoto(json: $0) } ?? []
		self.layoutRows = PhotosetLayoutRows(photos: self.photos, layoutString: json["photoset_layout"].string)
		self.dialogueEntries = json["dialogue"].array?.map { PostDialogueEntry(json: $0) } ?? []

		self.body = Post.bodyStringFromJSON(json)
		self.secondaryBody = Post.secondaryBodyStringFromJSON(json)

		self.asker = json["asking_name"].string
		self.question = json["question"].string
		self.title = json["title"].string
		self.thumbnailURLString = json["thumbnail_url"].string
		self.permalinkURLString = json["permalink_url"].string
		self.videoType = json["video_type"].string
		self.videoURLString = json["video_url"].string
		self.videoWidth = json["thumbnail_width"].float
		self.videoHeight = json["thumbnail_height"].float
		self.liked = json["liked"].bool!
		if let trail = json["trail"].array {
			self.bodies = trail.map { $0["content"].string }.filter { $0 != nil }.map { $0! }
		} else {
			self.bodies = []
		}
		if let trail = json["trail"].array {
			self.usernames = trail.map { $0["blog"]["name"].string }.filter { $0 != nil }.map { $0! }
		} else {
			self.usernames = []
		}
	}

	func htmlBodyWithWidth(width: CGFloat) -> String? {
		return body?.htmlStringWithTumblrStyle(width)
	}

	func htmlSecondaryBodyWithWidth(width: CGFloat) -> String? {
		guard let secondaryBody = secondaryBody else {
			return nil
		}

		var stringToStyle: String?

		switch type {
		case "quote":
			stringToStyle = "<table><tr><td>-&nbsp;</td><td>\(secondaryBody)</td></tr></table>"
		default:
			stringToStyle = secondaryBody
		}

		return stringToStyle?.htmlStringWithTumblrStyle(width)
	}

//	func htmlBodyAtIndex(index: Int) -> String? {
//		return bodies[index].htmlStringWithTumblrStyle(<#T##width: CGFloat##CGFloat#>)
//	}

	func videoURL() -> NSURL? {
		guard self.type == "video" else {
			return nil
		}

		guard let videoType = self.videoType else {
			return nil
		}

		switch videoType {
		case "vine":
			guard
				let permalinkURLString = permalinkURLString,
				let permalinkURL = NSURL(string: permalinkURLString),
				let documentData = NSData(contentsOfURL: permalinkURL),
				let document = NSString(data: documentData, encoding: NSASCIIStringEncoding) as? String,
				let metaStringRange = document.rangeOfString("twitter:player:stream.*?content=\".*?\"", options: .RegularExpressionSearch)
			else {
				return nil
			}

			let metaString = document.substringWithRange(metaStringRange)

			guard
				var urlStringRange = metaString.rangeOfString("http.*?\"", options: .RegularExpressionSearch)
			else {
				return nil
			}

			urlStringRange.endIndex = urlStringRange.endIndex.predecessor()

			return NSURL(string: metaString.substringWithRange(urlStringRange))
		case "youtube":
			if let permalinkURLString = permalinkURLString {
				return NSURL(string: permalinkURLString)
			}
		default:
			if let videoURLString = videoURLString {
				return NSURL(string: videoURLString)
			}
		}

		return nil
	}

	func videoHeightWidthWidth(width: CGFloat) -> CGFloat? {
		guard self.type != "video" else {
			return nil
		}

		guard
			let videoWidth = videoWidth,
			let videoHeight = videoHeight
		else {
			return nil
		}

		return floor(CGFloat(videoHeight / videoWidth) * width)
	}
}

extension Post {
	class func bodyStringFromJSON(json: JSON) -> String? {
		guard let type = json["type"].string else {
			return nil
		}

		var bodyString: String?

		switch type {
		case "photo":
			bodyString = json["caption"].string
		case "text":
			bodyString = json["body"].string
		case "answer":
			bodyString = json["answer"].string
		case "quote":
			bodyString = json["text"].string
		case "link":
			bodyString = json["description"].string
		case "video":
			bodyString = json["caption"].string
		case "audio":
			bodyString = json["caption"].string
		default:
			bodyString = nil
		}

		if bodyString?.characters.count > 0 {
			return bodyString
		}

		return nil
	}

	class func secondaryBodyStringFromJSON(json: JSON) -> String? {
		guard let type = json["type"].string else {
			return nil
		}
		var secondaryBodyString: String?

		switch type {
		case "quote":
			secondaryBodyString = json["source"].string
		case "audio":
			secondaryBodyString = json["player"].string
		default:
			secondaryBodyString = nil
		}

		if secondaryBodyString?.characters.count > 0 {
			return secondaryBodyString
		}

		return nil
	}
}
