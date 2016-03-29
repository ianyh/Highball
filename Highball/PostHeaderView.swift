//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import PINCache
import TMTumblrSDK

class PostHeaderView: UITableViewHeaderFooterView {
	var tapHandler: ((Post, UIView) -> ())?

	private let avatarLoadQueue = dispatch_queue_create("avatarLoadQueue", nil)
	private var avatarImageView: UIImageView!
	private var usernameLabel: UILabel!
	private var topUsernameLabel: UILabel!
	private var bottomUsernameLabel: UILabel!
	private var timeLabel: UILabel!

	var post: Post? {
		didSet {
			guard let post = self.post else {
				return
			}

			let blogName = post.blogName

			avatarImageView.image = UIImage(named: "Placeholder")

			PINCache.sharedCache().objectForKey("avatar:\(blogName)") { cache, key, object in
				if let data = object as? NSData {
					dispatch_async(self.avatarLoadQueue) {
						let image = UIImage(data: data)
						dispatch_async(dispatch_get_main_queue()) {
							self.avatarImageView.image = image
						}
					}
				} else {
					TMAPIClient.sharedInstance().avatar(blogName, size: 80) { response, error in
						if let error = error {
							print(error)
						} else {
							guard let data = response as? NSData else {
								return
							}
							PINCache.sharedCache().setObject(data, forKey: "avatar:\(blogName)", block: nil)
							dispatch_async(self.avatarLoadQueue) {
								let image = UIImage(data: data)
								dispatch_async(dispatch_get_main_queue()) {
									self.avatarImageView.image = image
								}
							}
						}
					}
				}
			}

			if let rebloggedBlogName = post.rebloggedBlogName {
				usernameLabel.text = nil
				topUsernameLabel.text = blogName
				bottomUsernameLabel.text = rebloggedBlogName
			} else {
				usernameLabel.text = blogName
				topUsernameLabel.text = nil
				bottomUsernameLabel.text = nil
			}

			timeLabel.text = NSDate(timeIntervalSince1970: NSTimeInterval(post.timestamp)).stringWithRelativeFormat()
		}
	}

	override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	private func setUpCell() {
		let blurEffect = UIBlurEffect(style: .ExtraLight)
		let blurView = UIVisualEffectView(effect: blurEffect)

		backgroundView = blurView

		avatarImageView = UIImageView()
		avatarImageView.layer.cornerRadius = 20
		avatarImageView.clipsToBounds = true

		usernameLabel = UILabel()
		usernameLabel.font = UIFont.boldSystemFontOfSize(16)

		topUsernameLabel = UILabel()
		topUsernameLabel.font = UIFont.boldSystemFontOfSize(16)

		bottomUsernameLabel = UILabel()
		bottomUsernameLabel.font = UIFont.systemFontOfSize(12)

		timeLabel = UILabel()
		timeLabel.font = UIFont.systemFontOfSize(14)

		let button = UIButton(type: .System)
		button.addTarget(self, action: #selector(PostHeaderView.tap(_:)), forControlEvents: UIControlEvents.TouchUpInside)

		let borderView = UIView()
		borderView.backgroundColor = UIColor.grayColor()
		borderView.alpha = 0.5

		contentView.addSubview(avatarImageView)
		contentView.addSubview(usernameLabel)
		contentView.addSubview(topUsernameLabel)
		contentView.addSubview(bottomUsernameLabel)
		contentView.addSubview(timeLabel)
		contentView.addSubview(button)
		contentView.addSubview(borderView)

		constrain(avatarImageView, contentView) { avatarImageView, contentView in
			avatarImageView.centerY == contentView.centerY
			avatarImageView.left == contentView.left + 4
			avatarImageView.width == 40
			avatarImageView.height == 40
		}

		constrain(usernameLabel, avatarImageView, contentView) { usernameLabel, avatarImageView, contentView in
			usernameLabel.centerY == contentView.centerY
			usernameLabel.left == avatarImageView.right + 4
			usernameLabel.height == 30
		}

		constrain(topUsernameLabel, avatarImageView, contentView) { usernameLabel, avatarImageView, contentView in
			usernameLabel.centerY == contentView.centerY - 8
			usernameLabel.left == avatarImageView.right + 4
			usernameLabel.height == 20
		}

		constrain(bottomUsernameLabel, avatarImageView, contentView) { usernameLabel, avatarImageView, contentView in
			usernameLabel.centerY == contentView.centerY + 8
			usernameLabel.left == avatarImageView.right + 4
			usernameLabel.height == 20
		}

		constrain(timeLabel, usernameLabel, contentView) { timeLabel, usernameLabel, contentView in
			timeLabel.centerY == contentView.centerY
			timeLabel.right == contentView.right - 8.0
			timeLabel.height == 30
		}

		constrain(button, contentView) { button, contentView in
			button.edges == contentView.edges; return
		}

		constrain(borderView, contentView) { borderView, contentView in
			borderView.height == 1
			borderView.right == contentView.right
			borderView.bottom == contentView.bottom
			borderView.left == contentView.left
		}
	}

	func tap(sender: UIButton) {
		guard let post = post else {
			return
		}

		tapHandler?(post, self)
	}
}
