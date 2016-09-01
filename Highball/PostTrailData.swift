//
//  PostTrailData.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 4/3/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import Mapper

public struct PostTrailData: Mappable {
	public let username: String
	public let content: String

	public init(map: Mapper) throws {
		username = try map.from("blog.name")
		content = try map.from("content")
	}
}
