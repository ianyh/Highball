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
        evaluateJavaScript("var body = document.body, html = document.documentElement; Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);", completionHandler: { result, error in
            if let _ = error {
                completion(0)
            } else if let height = JSON(result!).int {
                completion(CGFloat(height))
            } else {
                completion(0)
            }
        })
    }
}
