//
//  PostDialogueEntryTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

class PostDialogueEntryTableViewCell: UITableViewCell {

    var contentLabel: UILabel!

    var dialogueEntry: PostDialogueEntry? {
        didSet {
            if let dialogueEntry = self.dialogueEntry {
                self.contentLabel.attributedText = dialogueEntry.formattedString()
            }
        }
    }

    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    func setUpCell() {
        self.contentLabel = UILabel()

        self.contentLabel.numberOfLines = 0

        self.contentView.addSubview(self.contentLabel)
        
        layout(self.contentLabel, self.contentView) { label, view in
            label.left == view.left + 20
            label.right == view.right - 20
            label.top == view.top + 3
//            label.bottom == view.bottom - 3
        }
    }

    class func heightForPostDialogueEntry(post: PostDialogueEntry!, width: CGFloat!) -> CGFloat {
        let extraHeight: CGFloat = 3 + 3
        let modifiedWidth = width - 20 - 20
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let content = post.formattedString()
        let contentRect = content.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)

        return extraHeight + ceil(contentRect.size.height)
    }

}
