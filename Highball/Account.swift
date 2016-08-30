//
//  Account.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import RealmSwift

public class Account: Object {
	public dynamic var name: String!
	public dynamic var token: String!
	public dynamic var tokenSecret: String!
	public let blogs = List<UserBlog>()

	public var primaryBlog: UserBlog {
		return blogs.filter { $0.isPrimary }.first!
	}

	public override static func primaryKey() -> String {
		return "name"
	}

	public override static func ignoredProperties() -> [String] {
		return ["primaryBlog"]
	}
}
