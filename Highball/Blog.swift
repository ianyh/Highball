//
//  Blog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import Mapper

struct Blog: Mappable {
	let title: String
	let name: String

	init(map: Mapper) throws {
		try title = map.from("title")
		try name = map.from("name")
	}
}
