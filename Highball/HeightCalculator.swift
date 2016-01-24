//
//  HeightCalculator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import Foundation
import SwiftyJSON
import WebKit

private class WebViewDelegate: NSObject, WKNavigationDelegate {
	private let webView: WKWebView

	private var completion: ((CGFloat) -> ())?

	init(webView: WKWebView) {
		self.webView = webView
		super.init()
		webView.navigationDelegate = self
	}

	func calculateHeightWithHTMLString(htmlString: String, completion: (CGFloat) -> ()) {
		self.completion = completion

		webView.loadHTMLString(htmlString, baseURL: nil)
	}

	@objc func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		webView.getDocumentHeight { height in
			self.completion!(height)
		}
	}

	@objc func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
		self.completion!(0)
	}
}

struct HeightCalculator {
	private let post: Post
	private let width: CGFloat
	private let webView: WKWebView

	private let webViewDelegate: WebViewDelegate

	init(post: Post, width: CGFloat, webView: WKWebView) {
		self.post = post
		self.width = width
		self.webView = webView
		webViewDelegate = WebViewDelegate(webView: webView)

		webView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
	}

	func calculateHeight(secondary: Bool = false, completion: (height: CGFloat?) -> ()) {
		let htmlStringMethod = secondary ? Post.htmlSecondaryBodyWithWidth : Post.htmlBodyWithWidth

		guard let content = htmlStringMethod(post)(width) else {
			dispatch_async(dispatch_get_main_queue()) {
				completion(height: nil)
			}
			return
		}

		webViewDelegate.calculateHeightWithHTMLString(content) { height in
			completion(height: height)
		}
	}
}

private extension WKWebView {
	func getDocumentHeight(completion: (CGFloat) -> ()) {
		let javascriptString = "" +
			"var body = document.body;" +
			"var html = document.documentElement;" +
			"Math.max(" +
			"   body.scrollHeight," +
			"   body.offsetHeight," +
			"   html.clientHeight," +
			"   html.offsetHeight" +
			");"
		evaluateJavaScript(javascriptString) { result, error in
			if let error = error {
				print(error)
				completion(0)
			} else if let result = result, let height = JSON(result).int {
				completion(CGFloat(height))
			} else {
				completion(0)
			}
		}
	}
}
