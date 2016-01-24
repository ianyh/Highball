//
//  Blog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON

private let jsonCodingKey = "jsonCodingKey"

class UserBlog: Blog {
	let primary: Bool

	override init(json: JSON) {
		self.primary = json["primary"].boolValue
		super.init(json: json)
	}

	required init?(coder aDecoder: NSCoder) {
		let jsonData = aDecoder.decodeObjectForKey(jsonCodingKey) as! NSData!
		let json = JSON(data: jsonData)
		self.primary = json["primary"].boolValue
		super.init(coder: aDecoder)
	}
}

class Blog: NSObject, NSCoding {
	let name: String
	let url: String
	let title: String

	private let json: JSON

	init(json: JSON) {
		self.json = json
		self.name = json["name"].string!
		self.url = json["url"].string!
		self.title = json["title"].string!
	}

	required init?(coder aDecoder: NSCoder) {
		let jsonData = aDecoder.decodeObjectForKey(jsonCodingKey) as! NSData!
		let json = JSON(data: jsonData)
		self.json = json
		self.name = json["name"].string!
		self.url = json["url"].string!
		self.title = json["title"].string!
	}

	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(try! json.rawData(), forKey: jsonCodingKey)
	}
}
