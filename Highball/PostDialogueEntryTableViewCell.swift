//
//  PostDialogueEntryTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostDialogueEntryTableViewCell: WCFastCell {

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

        layout(self.contentLabel, self.contentView) { contentLabel, contentView in
            contentLabel.left == contentView.left + 20
            contentLabel.right == contentView.right - 20
            contentLabel.top == contentView.top + 3
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
