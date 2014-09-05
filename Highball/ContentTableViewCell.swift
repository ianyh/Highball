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
        self.contentWebView.scrollView.scrollEnabled = false

        self.contentView.addSubview(self.contentWebView)

        layout2(self.contentWebView, self.contentView) { webView, view in
            webView.top == view.top
            webView.right == view.right
            webView.bottom == view.bottom
            webView.left == view.left
        }
    }

}
