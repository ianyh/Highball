//
//  NSDate+Relative.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/14/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import FormatterKit

private let formatterKey = "HighballTimeIntervalFormatterKey"

extension Date {
	func stringWithRelativeFormat() -> String {
		var intervalFormatter = Thread.current.threadDictionary[formatterKey] as? TTTTimeIntervalFormatter

		if intervalFormatter == nil {
			intervalFormatter = TTTTimeIntervalFormatter()
			Thread.current.threadDictionary[formatterKey] = intervalFormatter
		}

		return intervalFormatter!.string(forTimeInterval: timeIntervalSinceNow)
	}
}
