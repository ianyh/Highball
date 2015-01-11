//
//  PostQuestionTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/30/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostQuestionTableViewCell: WCFastCell {
    var bubbleView: UIView!
    var askerLabel: UILabel!
    var contentLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let asker = post.asker!

                self.askerLabel.text = "\(asker) said:"
                self.contentLabel.text = post.question!
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
        self.bubbleView = UIView()
        self.askerLabel = UILabel()
        self.contentLabel = UILabel()

        self.bubbleView.backgroundColor = UIColor(white: 245.0/255.0, alpha: 1)
        self.bubbleView.layer.borderColor = UIColor(white: 217.0/255.0, alpha: 1).CGColor
        self.bubbleView.layer.borderWidth = 1

        self.askerLabel.font = UIFont.systemFontOfSize(14)
        self.askerLabel.textColor = UIColor(white: 166.0/255.0, alpha: 1)

        self.contentLabel.font = UIFont.systemFontOfSize(14)
        self.contentLabel.textColor = UIColor(white: 68.0/255.0, alpha: 1)
        self.contentLabel.numberOfLines = 0

        self.contentView.addSubview(self.bubbleView)
        self.contentView.addSubview(self.askerLabel)
        self.contentView.addSubview(self.contentLabel)

        layout(self.bubbleView, self.contentView) { bubbleView, contentView in
            bubbleView.edges == inset(contentView.edges, 1, 0); return
        }

        layout(self.askerLabel, self.bubbleView) { askerLabel, bubbleView in
            askerLabel.left == bubbleView.left + 10
            askerLabel.right == bubbleView.right - 10
            askerLabel.top == bubbleView.top + 12
            askerLabel.height == 20
        }

        layout(self.contentLabel, self.askerLabel, self.bubbleView) { contentLabel, askerLabel, bubbleView in
            contentLabel.top == askerLabel.top + 14
            contentLabel.left == bubbleView.left + 14
            contentLabel.right == bubbleView.right - 14
            contentLabel.bottom == bubbleView.bottom - 8
        }
    }

    class func heightForPost(post: Post!, width: CGFloat!) -> CGFloat {
        let question = post.question! as NSString
        let questionAttributes = [ NSFontAttributeName : UIFont.systemFontOfSize(14) ]
        let modifiedWidth = width - 16 - 28
        let extraHeight: CGFloat = 12 + 20 + 14 + 8
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let questionRect = question.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: questionAttributes, context: nil)

        return extraHeight + ceil(questionRect.size.height)
    }

}
