//
//  PostDialogueEntry.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import Mapper
import SwiftyJSON
import UIKit

struct PostDialogueEntry: Mappable {
	let formattedString: NSAttributedString

	init(map: Mapper) throws {
		let label: String = try map.from("label")
		let phrase: String = try map.from("phrase")

		var labelAttributes: [String: AnyObject] = [:]
		var phraseAttributes: [String: AnyObject] = [:]
		let attributedString = NSMutableAttributedString(string: "\(label) \(phrase)")

		labelAttributes[NSFontAttributeName] = UIFont(name: "Courier-Bold", size: 14)
		phraseAttributes[NSFontAttributeName] = UIFont(name: "Courier", size: 14)

		// swiftlint:disable legacy_constructor
		attributedString.setAttributes(labelAttributes, range: NSMakeRange(0, label.characters.count))
		attributedString.setAttributes(phraseAttributes, range: NSMakeRange(label.characters.count, phrase.characters.count + 1))
		// swiftlint:enable legacy_constructor

		formattedString = attributedString
	}
}
