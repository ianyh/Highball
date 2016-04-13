//
//  HeightCalculator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON
import YYText

struct HeightCalculator {
	private let post: Post
	private let width: CGFloat

	init(post: Post, width: CGFloat) {
		self.post = post
		self.width = width
	}

	func calculateHeight(secondary: Bool = false, completion: (height: CGFloat?) -> ()) {
		let htmlStringMethod = secondary ? Post.htmlSecondaryBodyWithWidth : Post.htmlBodyWithWidth

		guard let content = htmlStringMethod(post)(width), let data = content.dataUsingEncoding(NSUTF8StringEncoding) else {
			dispatch_async(dispatch_get_main_queue()) {
				completion(height: nil)
			}
			return
		}

		calculateHeightWithAttributedStringData(data, completion: completion)
	}

	func calculateBodyHeightAtIndex(index: Int, completion: (height: CGFloat?) -> ()) {
		let trailData = post.trailData[index]
		let htmlStringMethod = trailData.content.htmlStringWithTumblrStyle(width)

		guard let data = htmlStringMethod.dataUsingEncoding(NSUTF8StringEncoding) else {
			dispatch_async(dispatch_get_main_queue()) {
				completion(height: nil)
			}
			return
		}

		calculateHeightWithAttributedStringData(data, completion: completion)
	}

	func calculateHeightWithAttributedStringData(data: NSData, completion: (height: CGFloat?) -> ()) {
		let postContent = PostContent(htmlData: data)
		let string = postContent.attributedStringForDisplayWithLinkHandler(nil)
		let textLayout = YYTextLayout(containerSize: CGSize(width: width - 20, height: CGFloat.max), text: string)
		let size = textLayout!.textBoundingSize

		dispatch_async(dispatch_get_main_queue()) {
			completion(height: ceil(size.height + 40))
		}
	}
}
