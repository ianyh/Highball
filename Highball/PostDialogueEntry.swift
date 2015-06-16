//
//  PostDialogueEntry.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON

class PostDialogueEntry {
    private let json: JSON
    let formattedString: NSAttributedString

    required init(json: JSON) {
        self.json = json

        let label = self.json["label"].string!
        let phrase = self.json["phrase"].string!
        var labelAttributes = Dictionary<NSObject, AnyObject>()
        var phraseAttributes = Dictionary<NSObject, AnyObject>()
        let attributedString = NSMutableAttributedString(string: "\(label) \(phrase)")
        
        labelAttributes[NSFontAttributeName] = UIFont(name: "Courier-Bold", size: 14)
        phraseAttributes[NSFontAttributeName] = UIFont(name: "Courier", size: 14)
        
        attributedString.setAttributes(labelAttributes, range: NSMakeRange(0, count(label)))
        attributedString.setAttributes(phraseAttributes, range: NSMakeRange(count(label), count(phrase) + 1))
        
        self.formattedString = attributedString
    }
}
