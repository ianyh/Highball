//
//  PostQuestionTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/30/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import WCFastCell

class PostQuestionTableViewCell: WCFastCell {
    var bubbleView: UIView!
    var askerLabel: UILabel!
    var contentLabel: UILabel!

    var post: Post? {
        didSet {
            guard let post = post else {
                return
            }

            let asker = post.asker!
            
            askerLabel.text = "\(asker) said:"
            contentLabel.text = post.question!
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCell()
    }

    func setUpCell() {
        bubbleView = UIView()
        askerLabel = UILabel()
        contentLabel = UILabel()

        bubbleView.backgroundColor = UIColor(white: 245.0/255.0, alpha: 1)
        bubbleView.layer.borderColor = UIColor(white: 217.0/255.0, alpha: 1).CGColor
        bubbleView.layer.borderWidth = 1

        askerLabel.font = UIFont.systemFontOfSize(14)
        askerLabel.textColor = UIColor(white: 166.0/255.0, alpha: 1)

        contentLabel.font = UIFont.systemFontOfSize(14)
        contentLabel.textColor = UIColor(white: 68.0/255.0, alpha: 1)
        contentLabel.numberOfLines = 0

        contentView.addSubview(bubbleView)
        contentView.addSubview(askerLabel)
        contentView.addSubview(contentLabel)

        constrain(bubbleView, contentView) { bubbleView, contentView in
            bubbleView.edges == inset(contentView.edges, 1, 0)
        }

        constrain(askerLabel, bubbleView) { askerLabel, bubbleView in
            askerLabel.left == bubbleView.left + 10
            askerLabel.right == bubbleView.right - 10
            askerLabel.top == bubbleView.top + 12
            askerLabel.height == 20
        }

        constrain(contentLabel, askerLabel, bubbleView) { contentLabel, askerLabel, bubbleView in
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
