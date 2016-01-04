//
//  PostDialogueEntry.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

class PostDialogueEntry {
	private let json: JSON
	let formattedString: NSAttributedString

	required init(json: JSON) {
		self.json = json

		let label = self.json["label"].string!
		let phrase = self.json["phrase"].string!
		var labelAttributes = Dictionary<String, AnyObject>()
		var phraseAttributes = Dictionary<String, AnyObject>()
		let attributedString = NSMutableAttributedString(string: "\(label) \(phrase)")

		labelAttributes[NSFontAttributeName] = UIFont(name: "Courier-Bold", size: 14)
		phraseAttributes[NSFontAttributeName] = UIFont(name: "Courier", size: 14)

		// swiftlint:disable legacy_constructor
		attributedString.setAttributes(labelAttributes, range: NSMakeRange(0, label.characters.count))
		attributedString.setAttributes(phraseAttributes, range: NSMakeRange(label.characters.count, phrase.characters.count + 1))
		// swiftlint:enable legacy_constructor

		self.formattedString = attributedString
	}
}
