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

public class UserBlogObject: Object {
	public dynamic var name: String!
	public dynamic var url: String!
	public dynamic var title: String!
	public dynamic var isPrimary: Bool = false
}

extension UserBlogObject: UserBlog {}
