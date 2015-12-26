//
//  ContentTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import WebKit
import Cartography
import WCFastCell

class ContentTableViewCell: WCFastCell, WKNavigationDelegate {
    var contentWebView: WKWebView!
    var webViewShouldLoad = false
    var content: String? {
        didSet {
            if let content = content {
                self.webViewShouldLoad = true
                self.contentWebView.loadHTMLString(content, baseURL: NSURL(string: ""))
            }
        }
    }

    var linkHandler: ((NSURL) -> ())?

    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    func setUpCell() {
        self.contentWebView = WKWebView(frame: self.contentView.frame)
        self.contentWebView.scrollView.scrollEnabled = false
        self.contentWebView.navigationDelegate = self

        self.contentView.addSubview(self.contentWebView)

        constrain(self.contentWebView, self.contentView) { contentWebView, contentView in
            contentWebView.edges == contentView.edges; return
        }
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if self.webViewShouldLoad {
            self.webViewShouldLoad = false
            decisionHandler(WKNavigationActionPolicy.Allow)
        } else {
            if navigationAction.navigationType == WKNavigationType.LinkActivated, let url = navigationAction.request.URL {
                if let handler = linkHandler {
                    handler(url)
                }
            }
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
    }
}
