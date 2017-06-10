//
//  Post.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import Mapper
import SwiftyJSON
import UIKit
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

enum ReblogType {
	case reblog
	case queue
}

struct Post: Mappable {
	let id: Int
	let type: String
	let blogName: String
	let rebloggedBlogName: String?
	let reblogKey: String
	let timestamp: Int
	let url: URL
	let shortURL: URL
	let tags: [String]
	let photos: [PostPhoto]
	let layout: PhotosetLayout
	let dialogueEntries: [PostDialogueEntry]
	let body: String?
	let secondaryBody: String?
	let asker: String?
	let question: String?
	let title: String?
	let permalinkURL: URL?
	let video: PostVideo?
	var liked = false
	let trailData: [PostTrailData]

	init(map: Mapper) throws {
		id = try map.from("id")
		type = try map.from("type")
		blogName = try map.from("blog_name")
		rebloggedBlogName = map.optionalFrom("reblogged_from_name")
		reblogKey = try map.from("reblog_key")
		timestamp = try map.from("timestamp")
		url = try map.from("post_url")
		shortURL = try map.from("short_url")

		let tagStrings: [String] = map.optionalFrom("tags") ?? []
		tags = tagStrings.map { "#\($0)" }

		photos = map.optionalFrom("photos") ?? []

		let layoutString: String? = map.optionalFrom("photoset_layout")
		layout = PhotosetLayout(photos: photos, layoutString: layoutString)

		dialogueEntries = map.optionalFrom("dialogue") ?? []

		body = Post.bodyStringFromMap(map)
		secondaryBody = Post.secondaryBodyStringFromMap(map)

		asker = map.optionalFrom("asking_name")
		question = map.optionalFrom("question")

		title = map.optionalFrom("title")

		permalinkURL = map.optionalFrom("permalink_url")

		if type == "video" {
			video = try PostVideo(map: map)
		} else {
			video = nil
		}

		liked = try map.from("liked")

		trailData = map.optionalFrom("trail")?.reversed() ?? []
	}

	func htmlBodyWithWidth(_ width: CGFloat) -> String? {
		return body?.htmlStringWithTumblrStyle(width)
	}

	func htmlSecondaryBodyWithWidth(_ width: CGFloat) -> String? {
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

	func videoURL() -> URL? {
		guard self.type == "video" else {
			return nil
		}

		guard let videoType = video?.type else {
			return nil
		}

		switch videoType {
		case "vine":
//			guard let permalinkURL = permalinkURL,
//				let documentData = try? Data(contentsOf: permalinkURL),
//				let document = NSString(data: documentData, encoding: String.Encoding.ascii.rawValue) as? String,
//				let metaStringRange = document.range(of: "twitter:player:stream.*?content=\".*?\"", options: .regularExpression)
//			else {
//				return nil
//			}
//
//			let metaString = document.substring(with: metaStringRange)
//
//			guard
//				var urlStringRange = metaString.range(of: "http.*?\"", options: .regularExpression)
//			else {
//				return nil
//			}
//
//			urlStringRange.endIndex = urlStringRange.index(before: urlStringRange.endIndex)
//
//			return URL(string: metaString.substring(with: urlStringRange))
			return nil
		case "youtube":
			return permalinkURL
		default:
			return video?.url as URL?
		}
	}

	func videoHeightWidthWidth(_ width: CGFloat) -> CGFloat? {
		guard self.type != "video" else {
			return nil
		}

		guard let videoWidth = video?.width, let videoHeight = video?.height else {
			return nil
		}

		return floor(CGFloat(videoHeight / videoWidth) * width)
	}
}

extension Post {
	static func bodyStringFromMap(_ map: Mapper) -> String? {
		guard let type: String = map.optionalFrom("type") else {
			return nil
		}

		var bodyString: String?

		switch type {
		case "photo":
			bodyString = map.optionalFrom("caption")
		case "text":
			bodyString = map.optionalFrom("body")
		case "answer":
			bodyString = map.optionalFrom("answer")
		case "quote":
			bodyString = map.optionalFrom("text")
		case "link":
			bodyString = map.optionalFrom("description")
		case "video":
			bodyString = map.optionalFrom("caption")
		case "audio":
			bodyString = map.optionalFrom("caption")
		default:
			bodyString = nil
		}

		if bodyString?.characters.count > 0 {
			return bodyString
		}

		return nil
	}

	static func secondaryBodyStringFromMap(_ map: Mapper) -> String? {
		guard let type: String = map.optionalFrom("type") else {
			return nil
		}

		var secondaryBodyString: String?

		switch type {
		case "quote":
			secondaryBodyString = map.optionalFrom("source")
		case "audio":
			secondaryBodyString = map.optionalFrom("player")
		default:
			secondaryBodyString = nil
		}

		if secondaryBodyString?.characters.count > 0 {
			return secondaryBodyString
		}

		return nil
	}
}
