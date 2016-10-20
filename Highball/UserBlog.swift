//
//  UserBlog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import RealmSwift

public protocol UserBlog {
	var name: String! { get }
	var url: String! { get }
	var title: String! { get }
	var isPrimary: Bool { get }
}

open class UserBlogObject: Object {
	open dynamic var name: String!
	open dynamic var url: String!
	open dynamic var title: String!
	open dynamic var isPrimary: Bool = false
}

extension UserBlogObject: UserBlog {}
