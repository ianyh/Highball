//
//  HeightCalculator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import DTCoreText
import Foundation
import SwiftyJSON

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

		let attributedString = NSAttributedString(HTMLData: data, options: [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0], documentAttributes: nil)
		let layouter = DTCoreTextLayouter(attributedString: attributedString)
		let maxRect = CGRect(x: 0, y: 0, width: width - 30, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		// swiftlint:disable legacy_constructor
		let entireString = NSMakeRange(0, attributedString.length)
		// swiftlint:enable legacy_constructor
		let layoutFrame = layouter.layoutFrameWithRect(maxRect, range: entireString)

		dispatch_async(dispatch_get_main_queue()) {
			completion(height: layoutFrame.frame.height + 20)
		}
	}

	func calculateBodyHeightAtIndex(index: Int, completion: (height: CGFloat?) -> ()) {
		let htmlStringMethod = post.bodies[index].htmlStringWithTumblrStyle(0)

		guard let data = htmlStringMethod.dataUsingEncoding(NSUTF8StringEncoding) else {
			dispatch_async(dispatch_get_main_queue()) {
				completion(height: nil)
			}
			return
		}

		let attributedString = NSAttributedString(HTMLData: data, options: [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0], documentAttributes: nil)
		let layouter = DTCoreTextLayouter(attributedString: attributedString)
		let maxRect = CGRect(x: 0, y: 0, width: width - 20, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		// swiftlint:disable legacy_constructor
		let entireString = NSMakeRange(0, attributedString.length)
		// swiftlint:enable legacy_constructor
		let layoutFrame = layouter.layoutFrameWithRect(maxRect, range: entireString)

		dispatch_async(dispatch_get_main_queue()) {
			completion(height: ceil(layoutFrame.frame.height) + 34)
		}
	}
}
