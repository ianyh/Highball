//
//  VideoTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/25/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import AVFoundation
import Cartography
import FLAnimatedImage
import Foundation
import PINRemoteImage
import Player

protocol VideoPlaybackCell {
	func isPlaying() -> Bool
	func play()
	func stop()
}

class VideoTableViewCell: UITableViewCell, VideoPlaybackCell {
	private var player: Player!
	private var thumbnailImageView: FLAnimatedImageView!
	var post: Post? {
		didSet {
			guard let post = post else {
				return
			}

			defer {
				loadVideo()
			}

			guard let thumbnailURL = post.video?.thumbnailURL else {
				return
			}

			thumbnailImageView.pin_setImageFromURL(thumbnailURL) { result in
				if result.resultType != .MemoryCache {
					self.thumbnailImageView.alpha = 0
					UIView.animateWithDuration(
						0.5,
						delay: 0.1,
						options: .AllowUserInteraction,
						animations: { self.thumbnailImageView.alpha = 1.0 },
						completion: nil
					)
				}
			}
		}
	}
	var urlString: String? {
		didSet {
			guard let urlString = urlString, url = NSURL(string: urlString) else {
				return
			}

			player.setUrl(url)
		}
	}

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		player.stop()
		thumbnailImageView.animatedImage = nil
		thumbnailImageView.hidden = false
		thumbnailImageView.image = nil
	}

	private func setUpCell() {
		player = Player()
		player.delegate = self
		player.muted = true
		player.playbackLoops = true

		thumbnailImageView = FLAnimatedImageView()

		thumbnailImageView.backgroundColor = UIColor.lightGrayColor()
		thumbnailImageView.contentMode = .ScaleAspectFit

		contentView.addSubview(player.view)
		contentView.addSubview(thumbnailImageView)

		constrain(player.view, contentView) { playerView, contentView in
			playerView.edges == contentView.edges
		}

		constrain(thumbnailImageView, contentView) { imageView, contentView in
			imageView.edges == contentView.edges
		}
	}

	func loadVideo() {
		guard let post = post, url = post.videoURL()?.absoluteString else {
			return
		}

		urlString = url
	}

	func isPlaying() -> Bool {
		return player.playbackState == .Playing
	}

	func play() {
		player.muted = false
		setPlayback(true)
	}

	func stop() {
		setPlayback(false)
	}

	private func setPlayback(playback: Bool) {
		thumbnailImageView.hidden = true
		if playback {
			player.playFromCurrentTime()
		} else {
			player.pause()
		}
	}
}

extension VideoTableViewCell: PlayerDelegate {
	func playerReady(player: Player) {

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
