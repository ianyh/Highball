//
//  PostVideo.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import Mapper

struct PostVideo: Mappable {
	let type: String
	let url: URL
	let thumbnailURL: URL
	let width: Double
	let height: Double

	init(map: Mapper) throws {
		type = try map.from("video_type")
		url = try map.from("video_url")
		thumbnailURL = try map.from("thumbnail_url")
		width = try map.from("thumbnail_width")
		height = try map.from("thumbnail_height")
	}
}
