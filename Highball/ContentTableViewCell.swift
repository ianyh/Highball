//
//  ContentTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import FLAnimatedImage
import PINCache
import PINRemoteImage
import TMTumblrSDK
import WCFastCell
import YYText

class ContentTableViewCell: WCFastCell {
	private let avatarLoadQueue = dispatch_queue_create("avatarLoadQueue", nil)

	private(set) var avatarImageView: UIImageView!
	private(set) var usernameLabel: UILabel!
	private(set) var textView: YYTextView!

	var width: CGFloat = 375
	private var postContent: PostContent?
	var trailData: PostTrailData? {
		didSet {
			avatarImageView.image = UIImage(named: "Placeholder")

			guard let trailData = trailData else {
				usernameLabel.text = nil
				content = nil
				return
			}

			PINCache.sharedCache().objectForKey("avatar:\(trailData.username)") { cache, key, object in
				if let data = object as? NSData {
					dispatch_async(self.avatarLoadQueue) {
						let image = UIImage(data: data)
						dispatch_async(dispatch_get_main_queue()) {
							self.avatarImageView.image = image
						}
					}
				} else {
					TMAPIClient.sharedInstance().avatar(trailData.username, size: 80) { response, error in
						if let error = error {
							print(error)
						} else {
							guard let data = response as? NSData else {
								return
							}
							PINCache.sharedCache().setObject(data, forKey: "avatar:\(trailData.username)", block: nil)
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

			usernameLabel.text = trailData.username
			content = trailData.content.htmlStringWithTumblrStyle(width)
		}
	}
	var content: String? {
		didSet {
			if let content = content {
				let data = content.dataUsingEncoding(NSUTF8StringEncoding)!
				var postContent = PostContent(htmlData: data)
				postContent.contentURLS().forEach { contentURL in
					let imageView = FLAnimatedImageView()
					imageView.backgroundColor = UIColor.purpleColor()
					imageView.pin_setImageFromURL(contentURL) { result in
						let size = result.image?.size ?? result.animatedImage.size
						let width = self.widthForURL?(url: contentURL.absoluteString) ?? min(size.width, self.width - 20)
						let scaledSize = CGSize(width: width, height: floor(size.height * width / size.width))

						postContent.setImageView(imageView, withSize: scaledSize, forAttachmentURL: contentURL)

						self.textView.attributedText = postContent.attributedStringForDisplayWithLinkHandler() { url in
							self.linkHandler?(url)
						}
						self.widthDidChange?(url: contentURL.absoluteString, width: scaledSize.width, height: scaledSize.height, imageView: imageView)
					}
				}
				textView.attributedText = postContent.attributedStringForDisplayWithLinkHandler() { url in
					self.linkHandler?(url)
				}
				usernameLabel.superview?.hidden = (postContent.attributedString.string.characters.count == 0)
			} else {
				textView.attributedText = NSAttributedString(string: "")
				usernameLabel.superview?.hidden = true
			}
		}
	}

	var linkHandler: ((NSURL) -> ())?
	var widthDidChange: ((url: String, width: CGFloat, height: CGFloat, imageView: FLAnimatedImageView) -> ())?
	var widthForURL: ((url: String) -> CGFloat?)?
	var imageViewForURL: ((url: String) -> FLAnimatedImageView?)?

	override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	func setUpCell() {
		contentView.clipsToBounds = true

		let usernameContainerView = UIView()

		avatarImageView = UIImageView()
		usernameLabel = UILabel()
		textView = YYTextView()

		usernameContainerView.backgroundColor = UIColor.whiteColor()

		avatarImageView.clipsToBounds = true
		avatarImageView.contentMode = .ScaleAspectFit
		avatarImageView.layer.cornerRadius = 4

		usernameLabel.font = UIFont.boldSystemFontOfSize(16)

		textView.editable = false
		textView.scrollEnabled = false
		textView.textContainerInset = UIEdgeInsetsZero
		textView.clipsToBounds = true

		usernameContainerView.addSubview(avatarImageView)
		usernameContainerView.addSubview(usernameLabel)
		contentView.addSubview(textView)
		contentView.addSubview(usernameContainerView)

		constrain([usernameContainerView, avatarImageView, usernameLabel, textView, contentView]) { views in
			let usernameContainerView = views[0]
			let avatarImageView = views[1]
			let usernameLabel = views[2]
			let textView = views[3]
			let contentView = views[4]

			usernameContainerView.top == contentView.top
			usernameContainerView.right <= contentView.right
			usernameContainerView.left == contentView.left
			usernameContainerView.height == 32

			avatarImageView.top == usernameContainerView.top + 4
			avatarImageView.bottom == usernameContainerView.bottom - 4
			avatarImageView.left == usernameContainerView.left + 6
			avatarImageView.height == 24
			avatarImageView.width == avatarImageView.height

			usernameLabel.top  == usernameContainerView.top + 4
			usernameLabel.right == usernameContainerView.right - 10
			usernameLabel.bottom == usernameContainerView.bottom - 4
			usernameLabel.left == avatarImageView.right + 4

			textView.top == usernameContainerView.bottom + 4
			textView.right == contentView.right - 10
			textView.bottom == contentView.bottom - 4
			textView.left == contentView.left + 10
		}

		layoutIfNeeded()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		widthDidChange = nil
		widthForURL = nil
	}
}
