//
//  UserBlog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import RealmSwift

protocol UserBlog {
	var name: String! { get }
	var url: String! { get }
	var title: String! { get }
	var isPrimary: Bool { get }
}

class UserBlogObject: Object {
	dynamic var name: String!
	dynamic var url: String!
	dynamic var title: String!
	dynamic var isPrimary: Bool = false
}

extension UserBlogObject: UserBlog {}
