//
//  NSDate+Relative.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/14/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import FormatterKit

private let formatterKey = "HighballTimeIntervalFormatterKey"

public extension NSDate {
	public func stringWithRelativeFormat() -> String {
		var intervalFormatter = NSThread.currentThread().threadDictionary[formatterKey] as? TTTTimeIntervalFormatter

		if intervalFormatter == nil {
			intervalFormatter = TTTTimeIntervalFormatter()
			NSThread.currentThread().threadDictionary[formatterKey] = intervalFormatter
		}

		return intervalFormatter!.stringForTimeInterval(timeIntervalSinceNow)
	}
}
