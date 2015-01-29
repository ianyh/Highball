//
//  VideoTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/25/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

@objc protocol VideoPlaybackCell {
    func isPlaying() -> Bool
    func play()
    func stop()
}

class VideoTableViewCell: UITableViewCell, VideoPlaybackCell {
    private var player: AVPlayer! {
        willSet {
            if let player = self.player {
                player.rate = 0.0
            }
        }
    }
    private var playerLayer: AVPlayerLayer! {
        willSet {
            if let playerLayer = self.playerLayer {
                playerLayer.removeFromSuperlayer()
            }
        }
        didSet {
            if let playerLayer = self.playerLayer {
                playerLayer.frame = self.contentView.layer.bounds
                self.contentView.layer.insertSublayer(playerLayer, atIndex: 0)
            }
        }
    }
    private var thumbnailImageView: FLAnimatedImageView!
    var post: Post? {
        didSet {
            if let post = self.post {
                if let thumbnailURLString = post.thumbnailURLString {
                    if let thumbnailURL = NSURL(string: thumbnailURLString) {
                        self.thumbnailImageView.setImageByTypeWithURL(thumbnailURL)
                    }
                }

                self.player = nil
                self.playerLayer = nil

                post.getVideoPlayer() { player in
                    self.player = player
                }
            }
        }
    }

    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        super.init()
        self.setUpCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.playerLayer = nil
        self.player = nil
        self.thumbnailImageView.hidden = false
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = self.playerLayer {
            CATransaction.begin()
            CATransaction.disableActions()
            playerLayer.frame = self.contentView.layer.bounds
            CATransaction.commit()
        }
    }

    private func setUpCell() {
        self.backgroundColor = UIColor.redColor()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playDidEnd:"), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

        self.thumbnailImageView = FLAnimatedImageView()

        self.thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
        self.thumbnailImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.contentView.addSubview(self.thumbnailImageView)

        layout(self.thumbnailImageView, self.contentView) { imageView, contentView in
            imageView.edges == contentView.edges; return
        }
    }

    func isPlaying() -> Bool {
        if let player = self.player {
            return player.rate == 1.0
        } else {
            return false
        }
    }

    func play() {
        self.setPlayback(true)
    }

    func stop() {
        self.setPlayback(false)
    }

    private func setPlayback(playback: Bool) {
        if let player = self.player {
            if let playerLayer = self.playerLayer {} else {
                self.playerLayer = AVPlayerLayer(player: player)
            }
            self.thumbnailImageView.hidden = true
            if playback {
                player.rate = 1.0
            } else {
                player.rate = 0.0
            }
        }
    }

    func playDidEnd(notification: NSNotification) {
        if let player = self.player {
            if let playerItem = notification.object as? AVPlayerItem {
                if player.currentItem == playerItem {
                    player.seekToTime(kCMTimeZero)
                    player.play()
                }
            }
        }
    }
}
