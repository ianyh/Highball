//
//  Conversation.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import Mapper

struct Conversation: Mappable {
	let id: String
	let participants: [Blog]

	init(map: Mapper) throws {
		id = try map.from("id")
		participants = try map.from("participants")
	}
}
