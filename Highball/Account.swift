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

open class AccountObject: Object {
	open dynamic var name: String!
	open dynamic var token: String!
	open dynamic var tokenSecret: String!
	open let blogObjects = List<UserBlogObject>()

	open var blogs: [UserBlog] {
		return blogObjects.map { $0 }
	}

	open override static func primaryKey() -> String {
		return "name"
	}

	open override static func ignoredProperties() -> [String] {
		return ["blogs"]
	}
}

extension AccountObject: Account {}
