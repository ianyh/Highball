//
//  PostPhoto.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Mapper
import SwiftyJSON
import UIKit

internal struct Size: Mappable {
	let width: Double
	let url: URL

	init(map: Mapper) throws {
		width = try map.from("width")
		url = try map.from("url")
	}
}

struct PostPhoto: Mappable {
	let width: CGFloat
	let height: CGFloat
	fileprivate let sizes: [Size]
	let widthToHeightRatio: Double?

	init(map: Mapper) throws {
		let width: Double = map.optionalFrom("original_size.width") ?? 0
		let height: Double = map.optionalFrom("original_size.height") ?? 0

		self.width = CGFloat(width)
		self.height = CGFloat(height)

		if width > 0 && height > 0 {
			widthToHeightRatio = width / height
		} else {
			widthToHeightRatio = 1.0
		}

		let originalSize: Size = try map.from("original_size")
		let alternateSizes: [Size] = try map.from("alt_sizes")

		sizes = ([originalSize] + alternateSizes).sorted { $0.width > $1.width }
	}

	func urlWithWidth(_ width: CGFloat) -> URL {
		let appDelegate = UIApplication.shared.delegate
		if let delegate = appDelegate as? AppDelegate, let reachability = delegate.reachability {
			if reachability.isReachableViaWiFi() {
				return sizes.first!.url
			}
		}

		let largerSizes = sizes.filter { $0.width > Double(width) }

		return largerSizes.last?.url ?? sizes.first!.url
	}
}
