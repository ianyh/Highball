//
//  PostLinkTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostLinkTableViewCell: WCFastCell {

    var bubbleView: UIView!
    var titleLabel: UILabel!
    var urlLabel: UILabel!
    
    var post: Post? {
        didSet {
            if let post = self.post {
                let url = NSURL(string: post.urlString()!)
                self.titleLabel.text = post.title()
                self.urlLabel.text = url.host!
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
        self.titleLabel = UILabel()
        self.urlLabel = UILabel()
        
        self.bubbleView.backgroundColor = UIColor(red: 86.0/255.0, green: 188.0/255.0, blue: 138.0/255.0, alpha: 1)
        self.bubbleView.clipsToBounds = true
        self.bubbleView.layer.cornerRadius = 5
        
        self.titleLabel.font = UIFont.boldSystemFontOfSize(19)
        self.titleLabel.textColor = UIColor.whiteColor()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = NSTextAlignment.Center
        
        self.urlLabel.font = UIFont.systemFontOfSize(12)
        self.urlLabel.textColor = UIColor(white: 1, alpha: 0.7)
        self.urlLabel.numberOfLines = 1
        self.urlLabel.textAlignment = NSTextAlignment.Center
        
        self.contentView.addSubview(self.bubbleView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.urlLabel)

        self.bubbleView.snp_makeConstraints { (maker) -> Void in
            maker.left.equalTo(self.contentView.snp_left).offset(8)
            maker.right.equalTo(self.contentView.snp_right).offset(-8)
            maker.top.equalTo(self.contentView.snp_top).offset(6)
            maker.bottom.equalTo(self.contentView.snp_bottom).offset(-6)
        }

        self.urlLabel.snp_makeConstraints { (maker) -> Void in
            maker.left.equalTo(self.bubbleView.snp_left).offset(20)
            maker.right.equalTo(self.bubbleView.snp_right).offset(-20)
            maker.bottom.equalTo(self.bubbleView.snp_bottom).offset(-14)
            maker.height.equalTo(16)
        }

        self.titleLabel.snp_makeConstraints { (maker) -> Void in
            maker.left.equalTo(self.bubbleView.snp_left).offset(20)
            maker.right.equalTo(self.bubbleView.snp_right).offset(-20)
            maker.top.equalTo(self.bubbleView.snp_top).offset(14)
        }
    }
    
    class func heightForPost(post: Post!, width: CGFloat!) -> CGFloat {
        let extraHeight: CGFloat = 6 + 14 + 14 + 16 + 14 + 6
        let modifiedWidth = width - 16 - 40
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let titleAttributes = [ NSFontAttributeName : UIFont.boldSystemFontOfSize(19) ]

        if let title = post.title() as NSString? {
            let titleRect = title.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: titleAttributes, context: nil)

            return extraHeight + ceil(titleRect.size.height)
        } else {
            let title = "" as NSString
            let titleRect = title.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: titleAttributes, context: nil)

            return extraHeight + ceil(titleRect.size.height)
        }
    }

}
