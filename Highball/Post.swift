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

public enum ReblogType {
	case Reblog
	case Queue
}

public struct Post: Mappable {
	public let id: Int
	public let type: String
	public let blogName: String
	public let rebloggedBlogName: String?
	public let reblogKey: String
	public let timestamp: Int
	public let url: NSURL
	public let shortURL: NSURL
	public let tags: [String]
	public let photos: [PostPhoto]
	public let layout: PhotosetLayout
	public let dialogueEntries: [PostDialogueEntry]
	public let body: String?
	public let secondaryBody: String?
	public let asker: String?
	public let question: String?
	public let title: String?
	public let permalinkURL: NSURL?
	public let video: PostVideo?
	public var liked = false
	public let trailData: [PostTrailData]

	public init(map: Mapper) throws {
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

		video = try? PostVideo(map: map)

		liked = try map.from("liked")

		trailData = map.optionalFrom("trail")?.reverse() ?? []
	}

	public func htmlBodyWithWidth(width: CGFloat) -> String? {
		return body?.htmlStringWithTumblrStyle(width)
	}

	public func htmlSecondaryBodyWithWidth(width: CGFloat) -> String? {
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

	public func videoURL() -> NSURL? {
		guard self.type == "video" else {
			return nil
		}

		guard let videoType = video?.type else {
			return nil
		}

		switch videoType {
		case "vine":
			guard let permalinkURL = permalinkURL,
				documentData = NSData(contentsOfURL: permalinkURL),
				document = NSString(data: documentData, encoding: NSASCIIStringEncoding) as? String,
				metaStringRange = document.rangeOfString("twitter:player:stream.*?content=\".*?\"", options: .RegularExpressionSearch)
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
			return permalinkURL
		default:
			return video?.url
		}
	}

	public func videoHeightWidthWidth(width: CGFloat) -> CGFloat? {
		guard self.type != "video" else {
			return nil
		}

		guard let videoWidth = video?.width, videoHeight = video?.height else {
			return nil
		}

		return floor(CGFloat(videoHeight / videoWidth) * width)
	}
}

public extension Post {
	public static func bodyStringFromMap(map: Mapper) -> String? {
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

	public static func secondaryBodyStringFromMap(map: Mapper) -> String? {
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
