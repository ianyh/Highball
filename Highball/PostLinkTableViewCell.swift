//
//  PostLinkTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

class PostLinkTableViewCell: UITableViewCell {

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
        
        layout(self.bubbleView, self.contentView) { view, contentView in
            view.left == contentView.left + 8
            view.right == contentView.right - 8
            view.top == contentView.top + 6
            view.bottom == contentView.bottom - 6
        }

        layout(self.urlLabel, self.bubbleView) { label, bubbleView in
            label.left == bubbleView.left + 20
            label.right == bubbleView.right - 20
            label.bottom == bubbleView.bottom - 14
            label.height == 16
        }

        layout(self.titleLabel, self.urlLabel, self.bubbleView) { label, urlLabel, view in
            label.left == view.left + 20
            label.right == view.right - 20
            label.top == view.top + 14
//            label.bottom == urlLabel.top - 14
        }
    }
    
    class func heightForPost(post: Post!, width: CGFloat!) -> CGFloat {
        let extraHeight: CGFloat = 6 + 14 + 14 + 16 + 14 + 6
        let modifiedWidth = width - 16 - 40
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let titleAttributes = [ NSFontAttributeName : UIFont.boldSystemFontOfSize(19) ]

        if let title = post.title() as NSString? {
            let titleRect = title.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: titleAttributes, context: nil)

            return extraHeight + titleRect.size.height
        } else {
            let title = "" as NSString
            let titleRect = title.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: titleAttributes, context: nil)

            return extraHeight + titleRect.size.height
        }
    }

}
