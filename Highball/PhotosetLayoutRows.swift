//
//  PhotosetLayoutRows.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public struct PhotosetLayout {
	public let rows: [Int]

	public init(photos: [PostPhoto], layoutString: String?) {
		if let layoutString = layoutString {
			var photosetLayoutRows: [Int] = []
			for character in layoutString.characters {
				photosetLayoutRows.append(Int("\(character)")!)
			}
			rows = photosetLayoutRows
		} else if photos.count == 0 {
			rows = []
		} else if photos.count % 2 == 0 {
			var layoutRows: [Int] = []
			for _ in 0...photos.count/2-1 {
				layoutRows.append(2)
			}
			rows = layoutRows
		} else if photos.count % 3 == 0 {
			var layoutRows: [Int] = []
			for _ in 0...photos.count/3-1 {
				layoutRows.append(3)
			}
			rows = layoutRows
		} else {
			var layoutRows: [Int] = []
			for _ in 0...photos.count-1 {
				layoutRows.append(1)
			}
			rows = layoutRows
		}
	}
}
