//
//  Account.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import RealmSwift

public protocol Account {
	var name: String! { get }
	var token: String! { get }
	var tokenSecret: String! { get }
	var blogs: [UserBlog] { get }
}

public extension Account {
	public var primaryBlog: UserBlog {
		return blogs.filter { $0.isPrimary }.first!
	}
}

public func == (lhs: Account, rhs: Account) -> Bool {
	return lhs.name == rhs.name
}

public class AccountObject: Object {
	public dynamic var name: String!
	public dynamic var token: String!
	public dynamic var tokenSecret: String!
	public let blogObjects = List<UserBlogObject>()

	public var blogs: [UserBlog] {
		return blogObjects.map { $0 }
	}

	public override static func primaryKey() -> String {
		return "name"
	}

	public override static func ignoredProperties() -> [String] {
		return ["blogs"]
	}
}

extension AccountObject: Account {}
