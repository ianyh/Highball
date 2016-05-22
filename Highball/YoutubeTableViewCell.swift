//
//  YoutubeTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/28/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Cartography
import UIKit
import XCDYouTubeKit

class YoutubeTableViewCell: VideoTableViewCell {
	override func loadVideo() {
		guard let post = post, videoURL = post.videoURL() else {
			return
		}

		let identifier = videoURL.absoluteString.componentsSeparatedByString("?v=")[1]
		XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier) { video, error in
			if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] {
				self.urlString = urlString.absoluteString
			} else if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.Medium360.rawValue] {
				self.urlString = urlString.absoluteString
			} else if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.Small240.rawValue] {
				self.urlString = urlString.absoluteString
			}
		}
	}
}
