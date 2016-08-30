//
//  UserBlog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import RealmSwift

public class UserBlog: Object {
	public dynamic var name: String!
	public dynamic var url: String!
	public dynamic var title: String!
	public dynamic var isPrimary: Bool = false
}
