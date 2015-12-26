//
//  VideoTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/25/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Foundation
import AVFoundation
import Cartography
import Player

@objc protocol VideoPlaybackCell {
    func isPlaying() -> Bool
    func play()
    func stop()
}

class VideoTableViewCell: UITableViewCell, VideoPlaybackCell {
    private var player: Player!
    private var thumbnailImageView: FLAnimatedImageView!
    var post: Post? {
        didSet {
            if let post = self.post {
                if let thumbnailURLString = post.thumbnailURLString {
                    if let thumbnailURL = NSURL(string: thumbnailURLString) {
                        self.thumbnailImageView.pin_setImageFromURL(thumbnailURL)
                    }
                }

                loadVideo()
            }
        }
    }
    var urlString: String? {
        didSet {
            if let urlString = urlString {
                player.setUrl(NSURL(string: urlString)!)
            }
        }
    }

    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.player.stop()
        self.thumbnailImageView.hidden = false
    }

    private func setUpCell() {
        self.player = Player()
        self.player.delegate = self
        self.player.muted = true
        self.player.playbackLoops = true

        self.thumbnailImageView = FLAnimatedImageView()

        self.thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
        self.thumbnailImageView.contentMode = UIViewContentMode.ScaleAspectFit

        self.contentView.addSubview(self.player.view)
        self.contentView.addSubview(self.thumbnailImageView)

        constrain(self.player.view, self.contentView) { playerView, contentView in
            playerView.edges == contentView.edges; return
        }

        constrain(self.thumbnailImageView, self.contentView) { imageView, contentView in
            imageView.edges == contentView.edges; return
        }
    }

    func loadVideo() {
        if let post = post {
            if let url = post.videoURL()?.absoluteString {
                self.urlString = url
            }
        }
    }

    func isPlaying() -> Bool {
        return self.player.playbackState == .Playing
    }

    func play() {
        self.player.muted = false
        self.setPlayback(true)
    }

    func stop() {
        self.setPlayback(false)
    }

    private func setPlayback(playback: Bool) {
        self.thumbnailImageView.hidden = true
        if playback {
            self.player.playFromCurrentTime()
        } else {
            self.player.pause()
        }
    }
}

extension VideoTableViewCell: PlayerDelegate {
    func playerReady(player: Player) {
//        self.play()
    }

    func playerPlaybackStateDidChange(player: Player) {

    }

    func playerBufferingStateDidChange(player: Player) {

    }

    func playerPlaybackWillStartFromBeginning(player: Player) {

    }

    func playerPlaybackDidEnd(player: Player) {

    }
}
