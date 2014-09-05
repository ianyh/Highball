//
//  Blog.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class Blog {
    let name: String!
    let url: String!
    let title: String!
    let primary: Bool!

    private let json: JSONValue!

    required init(json: JSONValue) {
        self.json = json
        self.name = json["name"].string!
        self.url = json["url"].string!
        self.title = json["title"].string!
        self.primary = json["primary"].bool!
    }
}
