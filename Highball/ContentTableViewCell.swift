//
//  ContentTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ContentTableViewCell: WCFastCell, UIWebViewDelegate {
    var contentWebView: UIWebView!
    var webViewShouldLoad = false
    var content: String? {
        didSet {
            if let content = content {
                self.webViewShouldLoad = true
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
        self.contentWebView.delegate = self

        self.contentView.addSubview(self.contentWebView)

        layout(self.contentWebView, self.contentView) { contentWebView, contentView in
            contentWebView.edges == contentView.edges; return
        }
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if self.webViewShouldLoad {
            self.webViewShouldLoad = false
            return true
        }
        return false
    }
}
