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
		guard let post = post, let videoURL = post.videoURL() else {
			return
		}

		let identifier = videoURL.absoluteString.components(separatedBy: "?v=")[1]
		XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { video, _ in
			if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] {
				self.urlString = urlString.absoluteString
			} else if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.medium360.rawValue] {
				self.urlString = urlString.absoluteString
			} else if let urlString = video?.streamURLs[XCDYouTubeVideoQuality.small240.rawValue] {
				self.urlString = urlString.absoluteString
			}
		}
	}
}
