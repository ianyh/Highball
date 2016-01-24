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
	var content: String? {
		didSet {
			if let content = content {
				contentWebView.loadHTMLString(content, baseURL: nil)
			} else {
				contentWebView.loadHTMLString("", baseURL: nil)
			}
		}
	}

	var linkHandler: ((NSURL) -> ())?

	override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	func setUpCell() {
		contentWebView = WKWebView(frame: contentView.frame)
		contentWebView.scrollView.scrollEnabled = false
		contentWebView.navigationDelegate = self

		contentView.addSubview(contentWebView)

		constrain(contentWebView, contentView) { contentWebView, contentView in
			contentWebView.edges == contentView.edges
		}
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if navigationAction.request.URL?.absoluteString == "about:blank" {
			decisionHandler(.Allow)
		} else {
			if navigationAction.navigationType == .LinkActivated, let url = navigationAction.request.URL {
				linkHandler?(url)
			}
			decisionHandler(.Cancel)
		}
	}

	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
	}
}
