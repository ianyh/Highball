//
//  WebViewCache.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import WebKit

class WebViewCache {
	private var memoryWarningObserver: AnyObject!
	private var resignActiveObserver: AnyObject!
	private var webViewCache: [WKWebView] = []

	init() {
		let notificationCenter = NSNotificationCenter.defaultCenter()
		self.memoryWarningObserver = notificationCenter.addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: nil) { [weak self] _ in
			self?.removeAll()
		}
		self.resignActiveObserver = notificationCenter.addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
			self?.removeAll()
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(memoryWarningObserver)
		NSNotificationCenter.defaultCenter().removeObserver(resignActiveObserver)
	}

	func pushWebView(webView: WKWebView) {
		webViewCache.append(webView)
	}

	func popWebView() -> WKWebView {
		if webViewCache.count > 0 {
			let webView = webViewCache.removeAtIndex(0)
			return webView
		}

		return WKWebView()
	}

	func removeAll() {
		webViewCache.removeAll()
	}
}
