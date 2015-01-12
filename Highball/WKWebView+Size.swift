//
//  WKWebView+Size.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/11/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import WebKit

extension WKWebView {
    convenience init(frame: CGRect, scaleToFit: Bool) {
        let jsScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let wkUScript = WKUserScript(source: jsScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(wkUScript)

        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController

        self.init(frame: frame, configuration: wkWebConfig)
    }
}
