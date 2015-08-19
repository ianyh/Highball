//
//  String+HTML.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

public extension String {

    func htmlStringWithTumblrStyle(width: CGFloat) -> String {
        let style = "body{max-width:\(width)px;color:rgb(68,68,68);font-size:14px;font-style:normal;font-weight:normal;line-height:19.6px;list-style-type:none;font-family: 'Helvetica Neue', HelveticaNeue, Helvetica, Arial, sans-serif;}blockquote{border-left-color:rgba(0, 0, 0, 0.117647);border-left-style:solid;border-left-width:4px;box-sizing:border-box;display:block;margin-bottom:0px;margin-top:0px;margin-left:2px;margin-right:10px;outline-color:rgb(68,68,68);outline-style:none;outline-width:0px;padding-left:15px;text-align:left;}a{box-sizing: border-box;cursor: auto;display: inline;color:rgb(68,68,68);font-size: 14px;font-style: normal;font-variant: normal;font-weight: normal;height: auto;line-height: 19.600000381469727px;list-style-type: none;outline-color: rgb(68, 68, 68);outline-style: none;outline-width: 0px;text-align: left;text-decoration: underline solid rgb(68, 68, 68);width: auto;}p{box-sizing: border-box;color: rgb(68, 68, 68);display: block;font-family: 'Helvetica Neue', HelveticaNeue, Helvetica, Arial, sans-serif;font-size: 14px;font-style: normal;font-variant: normal;font-weight: normal;line-height: 19.600000381469727px;list-style-type: none;margin-bottom: 10px;margin-left: 0px;margin-right: 0px;margin-top: 0px;}img{max-width:100%;height:auto!important;display: block;box-sizing: border-box;}td{vertical-align:text-top;}iframe{max-width:100%;}object{max-width:100%;}*{-webkit-touch-callout: none;-webkit-user-select: none;}"
        return "<html><head><style>\(style)</style><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no' /></head><body><div id='main'>\(self)</div></body></html>"
    }

}