//
//  HeightCalculator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import FLAnimatedImage
import Foundation
import SwiftyJSON
import YYText

class HeightCalculator {
	private let imageLoadingQueue = OperationQueue()
	private let imageLoadingUnderlyingQueue = DispatchQueue(label: "imageLoadingQueue")

	let post: Post
	let width: CGFloat

	init(post: Post, width: CGFloat) {
		self.post = post
		self.width = width

		imageLoadingQueue.underlyingQueue = imageLoadingUnderlyingQueue
	}

	func calculateHeight(_ secondary: Bool = false, completion: @escaping (_ height: CGFloat?) -> Void) {
		let htmlStringMethod = secondary ? Post.htmlSecondaryBodyWithWidth : Post.htmlBodyWithWidth

		guard let content = htmlStringMethod(post)(width), let data = content.data(using: String.Encoding.utf8) else {
			DispatchQueue.main.async {
				completion(nil)
			}
			return
		}

		calculateHeightWithAttributedStringData(data, completion: completion)
	}

	func calculateBodyHeightAtIndex(_ index: Int, completion: @escaping (_ height: CGFloat?) -> Void) {
		let trailData = post.trailData[index]
		let htmlStringMethod = trailData.content.htmlStringWithTumblrStyle(width)

		guard let data = htmlStringMethod.data(using: String.Encoding.utf8) else {
			DispatchQueue.main.async {
				completion(nil)
			}
			return
		}

		calculateHeightWithAttributedStringData(data, completion: completion)
	}

	func calculateHeightWithAttributedStringData(_ data: Data, completion: @escaping (_ height: CGFloat?) -> Void) {
		let postContent = PostContent(htmlData: data)
		let string = postContent.attributedStringForDisplayWithLinkHandler(nil)
		let textLayout = YYTextLayout(containerSize: CGSize(width: width - 20, height: CGFloat.greatestFiniteMagnitude), text: string)
		let size = textLayout!.textBoundingSize

		DispatchQueue.main.async {
			completion(ceil(size.height + 40))
		}
	}
}
