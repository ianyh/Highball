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
	let url: NSURL

	init(map: Mapper) throws {
		width = try map.from("width")
		url = try map.from("url")
	}
}

public struct PostPhoto: Mappable {
	public let width: CGFloat
	public let height: CGFloat
	private let sizes: [Size]
	public let widthToHeightRatio: Double?

	public init(map: Mapper) throws {
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

		sizes = ([originalSize] + alternateSizes).sort { $0.width > $1.width }
	}

	public func urlWithWidth(width: CGFloat) -> NSURL {
		let appDelegate = UIApplication.sharedApplication().delegate
		if let delegate = appDelegate as? AppDelegate, reachability = delegate.reachability {
			if reachability.isReachableViaWiFi() {
				return sizes.first!.url
			}
		}

		let largerSizes = sizes.filter { $0.width > Double(width) }

		return largerSizes.last?.url ?? sizes.first!.url
	}
}
