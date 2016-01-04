//
//  Blog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON

class Blog: NSObject, NSCoding {
	private let jsonCodingKey = "jsonCodingKey"

	let name: String
	let url: String
	let title: String
	let primary: Bool

	private let json: JSON

	required init(json: JSON) {
		self.json = json
		self.name = json["name"].string!
		self.url = json["url"].string!
		self.title = json["title"].string!
		self.primary = json["primary"].bool!
	}

	required init?(coder aDecoder: NSCoder) {
		let jsonData = aDecoder.decodeObjectForKey(jsonCodingKey) as! NSData!
		let json = JSON(data: jsonData)
		self.json = json
		self.name = json["name"].string!
		self.url = json["url"].string!
		self.title = json["title"].string!
		self.primary = json["primary"].bool!
	}

	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(try! self.json.rawData(), forKey: self.jsonCodingKey)
	}
}
