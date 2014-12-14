//
//  TitleTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/13/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//


import UIKit

class TitleTableViewCell: WCFastCell {

    var titleLabel: UILabel!

    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    func setUpCell() {
        self.titleLabel = UILabel()

        self.titleLabel.font = UIFont.boldSystemFontOfSize(16)
        self.titleLabel.numberOfLines = 0

        self.contentView.addSubview(self.titleLabel)

        layout(self.titleLabel, self.contentView) { titleLabel, contentView in
            titleLabel.left == contentView.left + 10
            titleLabel.right == contentView.right - 10
            titleLabel.top == contentView.top + 4
        }
    }


    class func heightForTitle(title: String, width: CGFloat!) -> CGFloat {
        let extraHeight: CGFloat = 4 + 4
        let modifiedWidth = width - 10 - 10
        let constrainedSize = CGSize(width: modifiedWidth, height: CGFloat.max)
        let attributedTitle = NSAttributedString(string: title, attributes: [ NSFontAttributeName : UIFont.boldSystemFontOfSize(16) ])
        let titleRect = attributedTitle.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)

        return extraHeight + ceil(titleRect.size.height)
    }

}
