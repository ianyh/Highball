//
//  ContentTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ContentTableViewCell: UITableViewCell {
    var contentWebView: UIWebView!
    var content: String? {
        didSet {
            if let content = content {
                self.contentWebView.loadHTMLString(content, baseURL: NSURL(string: ""))
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
        self.contentWebView = UIWebView()
        self.contentWebView.userInteractionEnabled = false
        self.contentWebView.scrollView.scrollEnabled = false

        self.contentView.addSubview(self.contentWebView)

        self.contentWebView.snp_makeConstraints { (maker) -> Void in
            maker.top.equalTo(self.contentView.snp_top)
            maker.right.equalTo(self.contentView.snp_right)
            maker.bottom.equalTo(self.contentView.snp_bottom)
            maker.left.equalTo(self.contentView.snp_left)
        }
    }
}
