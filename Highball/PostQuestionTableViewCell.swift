//
//  PostQuestionTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/30/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostQuestionTableViewCell: UITableViewCell {
    var bubbleView: UIView!
    var askerLabel: UILabel!
    var contentLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let asker = post.asker()!

                self.askerLabel.text = "\(asker) said:"
                self.contentLabel.text = post.question()!
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
        self.bubbleView.clipsToBounds = true
        self.bubbleView.layer.cornerRadius = 5
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

        self.bubbleView.snp_makeConstraints { (maker) -> Void in
            maker.left.equalTo(self.contentView.snp_left).offset(8)
            maker.right.equalTo(self.contentView.snp_right).offset(-8)
            maker.top.equalTo(self.contentView.snp_top).offset(6)
            maker.bottom.equalTo(self.contentView.snp_bottom).offset(-6)
        }

        self.askerLabel.snp_makeConstraints { (maker) -> Void in
            maker.left.equalTo(self.bubbleView.snp_left)
            maker.right.equalTo(self.bubbleView.snp_right)
            maker.top.equalTo(self.bubbleView.snp_top)
            maker.height.equalTo(20)
        }

        self.contentLabel.snp_makeConstraints { (maker) -> Void in
            maker.top.equalTo(self.askerLabel.snp_top).offset(14)
            maker.left.equalTo(self.bubbleView.snp_left).offset(14)
            maker.right.equalTo(self.bubbleView.snp_right).offset(14)
            maker.bottom.equalTo(self.bubbleView.snp_bottom).offset(-8)
        }
    }

    class func heightForPost(post: Post!, width: CGFloat!) -> CGFloat {
        let question = post.question()! as NSString
        let questionAttributes = [ NSFontAttributeName : UIFont.systemFontOfSize(14) ]
        let modifiedWidth = width - 16 - 28
        let extraHeight: CGFloat = 6 + 10 + 20 + 14 + 8 + 6
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let questionRect = question.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: questionAttributes, context: nil)

        return extraHeight + ceil(questionRect.size.height)
    }
}
