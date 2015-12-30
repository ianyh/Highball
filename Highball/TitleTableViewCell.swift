//
//  TitleTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/13/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import UIKit
import WCFastCell

class TitleTableViewCell: WCFastCell {
    var titleLabel: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCell()
    }

    func setUpCell() {
        titleLabel = UILabel()

        titleLabel.font = UIFont.boldSystemFontOfSize(16)
        titleLabel.numberOfLines = 0

        contentView.addSubview(titleLabel)

        constrain(titleLabel, contentView) { titleLabel, contentView in
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
