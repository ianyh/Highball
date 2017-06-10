//
//  Account.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import RealmSwift

protocol Account {
	var name: String! { get }
	var token: String! { get }
	var tokenSecret: String! { get }
	var blogs: [UserBlog] { get }
}

extension Account {
	var primaryBlog: UserBlog {
		return blogs.filter { $0.isPrimary }.first!
	}
}

func == (lhs: Account, rhs: Account) -> Bool {
	return lhs.name == rhs.name
}

class AccountObject: Object {
	dynamic var name: String!
	dynamic var token: String!
	dynamic var tokenSecret: String!
	let blogObjects = List<UserBlogObject>()

	var blogs: [UserBlog] {
		return blogObjects.map { $0 }
	}

	override static func primaryKey() -> String {
		return "name"
	}

	override static func ignoredProperties() -> [String] {
		return ["blogs"]
	}
}

extension AccountObject: Account {}
