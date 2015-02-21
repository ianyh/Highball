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
    private var player: MPMoviePlayerController!
    private var thumbnailImageView: FLAnimatedImageView!
    var post: Post? {
        didSet {
            if let post = self.post {
                if let thumbnailURLString = post.thumbnailURLString {
                    if let thumbnailURL = NSURL(string: thumbnailURLString) {
                        self.thumbnailImageView.setImageByTypeWithURL(thumbnailURL)
                    }
                }

                if let url = post.videoURL() {
                    self.player.contentURL = url
                    self.player.prepareToPlay()
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
        self.player.stop()
        self.thumbnailImageView.hidden = false
    }

    private func setUpCell() {
        self.player = MPMoviePlayerController()
        self.player.shouldAutoplay = false
        self.player.controlStyle = MPMovieControlStyle.None

        self.thumbnailImageView = FLAnimatedImageView()

        self.thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
        self.thumbnailImageView.contentMode = UIViewContentMode.ScaleAspectFit

        self.contentView.addSubview(self.player.view)
        self.contentView.addSubview(self.thumbnailImageView)

        layout(self.player.view, self.contentView) { playerView, contentView in
            playerView.edges == contentView.edges; return
        }

        layout(self.thumbnailImageView, self.contentView) { imageView, contentView in
            imageView.edges == contentView.edges; return
        }
    }

    func isPlaying() -> Bool {
        return self.player.playbackState == MPMoviePlaybackState.Playing
    }

    func play() {
        self.setPlayback(true)
    }

    func stop() {
        self.setPlayback(false)
    }

    private func setPlayback(playback: Bool) {
        self.thumbnailImageView.hidden = true
        if playback {
            self.player.play()
        } else {
            self.player.pause()
        }
    }
}
