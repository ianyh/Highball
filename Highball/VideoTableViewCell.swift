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
	fileprivate var player: Player!
	fileprivate var thumbnailImageView: FLAnimatedImageView!
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

			thumbnailImageView.pin_setImage(from: thumbnailURL as URL) { result in
				if result.resultType != .memoryCache {
					self.thumbnailImageView.alpha = 0
					UIView.animate(
						withDuration: 0.5,
						delay: 0.1,
						options: .allowUserInteraction,
						animations: { self.thumbnailImageView.alpha = 1.0 },
						completion: nil
					)
				}
			}
		}
	}
	var urlString: String? {
		didSet {
			guard let urlString = urlString, let url = URL(string: urlString) else {
				return
			}

			player.url = url
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
		thumbnailImageView.isHidden = false
		thumbnailImageView.image = nil
	}

	fileprivate func setUpCell() {
		player = Player()
		player.playerDelegate = self
		player.muted = true
		player.playbackLoops = true

		thumbnailImageView = FLAnimatedImageView()

		thumbnailImageView.backgroundColor = UIColor.lightGray
		thumbnailImageView.contentMode = .scaleAspectFit

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
		guard let post = post, let url = post.videoURL()?.absoluteString else {
			return
		}

		urlString = url
	}

	func isPlaying() -> Bool {
		return player.playbackState == .playing
	}

	func play() {
		player.muted = false
		setPlayback(true)
	}

	func stop() {
		setPlayback(false)
	}

	fileprivate func setPlayback(_ playback: Bool) {
		thumbnailImageView.isHidden = true
		if playback {
			player.playFromCurrentTime()
		} else {
			player.pause()
		}
	}
}

extension VideoTableViewCell: PlayerDelegate {
	func playerReady(_ player: Player) {

	}

	func playerPlaybackStateDidChange(_ player: Player) {

	}

	func playerBufferingStateDidChange(_ player: Player) {

	}

	func playerBufferTimeDidChange(_ bufferTime: Double) {

	}

	func playerPlaybackWillStartFromBeginning(_ player: Player) {

	}

	func playerPlaybackDidEnd(_ player: Player) {

	}
}
