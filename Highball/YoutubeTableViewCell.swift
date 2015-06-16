//
//  YoutubeTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/28/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography

let YoutubePlayerStartingNotification = "YoutubePlayerStartingNotification"

class YoutubeTableViewCell: UITableViewCell, YTPlayerViewDelegate, VideoPlaybackCell {
    private var youtubePlayer: YTPlayerView!
    private var thumbnailImageView: FLAnimatedImageView!
    var post: Post? {
        didSet {
            if let post = self.post {
                if let thumbnailURLString = post.thumbnailURLString {
                    if let thumbnailURL = NSURL(string: thumbnailURLString) {
                        self.thumbnailImageView.setImageByTypeWithURL(thumbnailURL, completion: nil)
                    }
                }

                self.youtubePlayer.clearVideo()
                if let videoURL = post.videoURL() {
                    self.youtubePlayer.cueVideoByURL(videoURL.absoluteString, startSeconds: 0.0, suggestedQuality: kYTPlaybackQualitySmall)
                }
            }
        }
    }

    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.thumbnailImageView.hidden = false
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func setUpCell() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerStarting:"), name: YoutubePlayerStartingNotification, object: nil)

        self.youtubePlayer = YTPlayerView()
        self.thumbnailImageView = FLAnimatedImageView()

        self.thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
        self.thumbnailImageView.contentMode = UIViewContentMode.ScaleAspectFit

        self.contentView.addSubview(self.youtubePlayer)
        self.contentView.addSubview(self.thumbnailImageView)

        layout(self.youtubePlayer, self.contentView) { youtubePlayer, contentView in
            youtubePlayer.edges == contentView.edges; return
        }

        layout(self.thumbnailImageView, self.contentView) { imageView, contentView in
            imageView.edges == contentView.edges; return
        }
    }

    func isPlaying() -> Bool {
        if self.youtubePlayer.playerState().value == kYTPlayerStatePlaying.value {
            return true
        }
        return false
    }

    func play() {
        NSNotificationCenter.defaultCenter().postNotificationName(YoutubePlayerStartingNotification, object: self.youtubePlayer)
        self.youtubePlayer.playVideo()
    }

    func stop() {
        self.youtubePlayer.stopVideo()
    }

    func playStarting(notification: NSNotification) {
        if let player = notification.object as? YTPlayerView {
            if player != self.youtubePlayer {
                self.youtubePlayer.stopVideo()
            }
        }
    }
}
