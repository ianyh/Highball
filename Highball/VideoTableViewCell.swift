//
//  VideoTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/25/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Foundation
import MediaPlayer

class VideoTableViewCell: UITableViewCell {
    private enum VideoPlaybackState {
        case Normal
        case StartingPlayback
        case Playing
    }
    private var moviePlayer: MPMoviePlayerController!
    private var thumbnailImageView: FLAnimatedImageView!
    private var playButton: UIButton!
    private var state = VideoPlaybackState.Normal
    var contentWidth: CGFloat = 0
    var post: Post? {
        didSet {
            if let post = self.post {
                if let thumbnailURLString = post.thumbnailURLString {
                    if let thumbnailURL = NSURL(string: thumbnailURLString) {
                        self.thumbnailImageView.setImageByTypeWithURL(thumbnailURL)
                    }
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
    }

    func setUpCell() {
        self.moviePlayer = MPMoviePlayerController()
        self.thumbnailImageView = FLAnimatedImageView()
        self.playButton = UIButton.buttonWithType(UIButtonType.System) as UIButton

        self.moviePlayer.scalingMode = MPMovieScalingMode.AspectFit

        self.thumbnailImageView.backgroundColor = UIColor.lightGrayColor()

        self.playButton.setTitle("Play", forState: UIControlState.Normal)
        self.playButton.addTarget(self, action: Selector("playVideo"), forControlEvents: UIControlEvents.TouchUpInside)

        self.contentView.addSubview(self.moviePlayer.view)
        self.contentView.addSubview(self.thumbnailImageView)
        self.contentView.addSubview(self.playButton)

        layout(self.moviePlayer.view, self.contentView) { moviePlayerView, contentView in
            moviePlayerView.edges == contentView.edges; return
        }

        layout(self.thumbnailImageView, self.contentView) { imageView, contentView in
            imageView.edges == contentView.edges; return
        }

        layout(self.playButton, self.contentView) { button, contentView in
            button.edges == contentView.edges; return
        }
    }

    func playVideo() {
        if self.state == VideoPlaybackState.Normal {
            if let post = self.post {
                self.state = VideoPlaybackState.StartingPlayback
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let videoURL = post.videoURL()
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.state == VideoPlaybackState.StartingPlayback {
                            self.thumbnailImageView.hidden = true
                            self.playButton.hidden = true
                            println(videoURL)
                            self.moviePlayer.contentURL = videoURL
                            self.moviePlayer.play()
                            self.state = VideoPlaybackState.Playing
                        }
                    }
                }
            }
        }
    }

    func pause() {
        self.moviePlayer.stop()
        self.state = VideoPlaybackState.Normal
    }

    func reset() {
        self.moviePlayer.stop()
        self.thumbnailImageView.hidden = false
        self.playButton.hidden = false
        self.state = VideoPlaybackState.Normal
    }
}
