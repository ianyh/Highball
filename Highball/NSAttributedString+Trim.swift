//
//  NSAttributedString+Trim.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 4/4/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

extension NSAttributedString {
	func attributedStringByTrimmingNewlines() -> NSAttributedString {
		var attributedString = self
		while attributedString.string.characters.first == "\n" {
			attributedString = attributedString.attributedSubstringFromRange(NSMakeRange(1, attributedString.string.characters.count - 1))
		}
		while attributedString.string.characters.last == "\n" {
			attributedString = attributedString.attributedSubstringFromRange(NSMakeRange(0, attributedString.string.characters.count - 1))
		}
		return attributedString
	}
}
