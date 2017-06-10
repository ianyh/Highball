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
	var tapHandler: ((Post, UIView) -> Void)?

	fileprivate let avatarLoadQueue = DispatchQueue(label: "avatarLoadQueue", attributes: [])
	fileprivate var avatarImageView: UIImageView!
	fileprivate var usernameLabel: UILabel!
	fileprivate var topUsernameLabel: UILabel!
	fileprivate var bottomUsernameLabel: UILabel!
	fileprivate var timeLabel: UILabel!

	var post: Post? {
		didSet {
			guard let post = self.post else {
				return
			}

			let blogName = post.blogName

			avatarImageView.image = UIImage(named: "Placeholder")

			PINCache.shared.object(forKeyAsync: "avatar:\(blogName)") { _, _, object in
				if let data = object as? Data {
					self.avatarLoadQueue.async {
						let image = UIImage(data: data)
						DispatchQueue.main.async {
							self.avatarImageView.image = image
						}
					}
				} else {
					TMAPIClient.sharedInstance().avatar(blogName, size: 80) { response, error in
						if let error = error {
							print(error)
						} else {
							guard let data = response as? Data else {
								return
							}
							PINCache.shared.setObject(data, forKey: "avatar:\(blogName)")
							self.avatarLoadQueue.async {
								let image = UIImage(data: data)
								DispatchQueue.main.async {
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

			timeLabel.text = Date(timeIntervalSince1970: TimeInterval(post.timestamp)).stringWithRelativeFormat()
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

	fileprivate func setUpCell() {
		let blurEffect = UIBlurEffect(style: .extraLight)
		let blurView = UIVisualEffectView(effect: blurEffect)

		backgroundView = blurView

		avatarImageView = UIImageView()
		avatarImageView.layer.cornerRadius = 4
		avatarImageView.clipsToBounds = true

		usernameLabel = UILabel()
		usernameLabel.font = UIFont.boldSystemFont(ofSize: 16)

		topUsernameLabel = UILabel()
		topUsernameLabel.font = UIFont.boldSystemFont(ofSize: 16)

		bottomUsernameLabel = UILabel()
		bottomUsernameLabel.font = UIFont.systemFont(ofSize: 12)

		timeLabel = UILabel()
		timeLabel.font = UIFont.systemFont(ofSize: 14)

		let button = UIButton(type: .system)
		button.addTarget(self, action: #selector(PostHeaderView.tap(_:)), for: UIControlEvents.touchUpInside)

		let borderView = UIView()
		borderView.backgroundColor = UIColor.gray
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
			avatarImageView.width == 36
			avatarImageView.height == 36
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

		constrain(timeLabel, usernameLabel, contentView) { timeLabel, _, contentView in
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

	func tap(_ sender: UIButton) {
		guard let post = post else {
			return
		}

		tapHandler?(post, self)
	}
}
