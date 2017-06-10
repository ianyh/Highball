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
	fileprivate let avatarLoadQueue = DispatchQueue(label: "avatarLoadQueue", attributes: [])

	fileprivate(set) var avatarImageView: UIImageView!
	fileprivate(set) var usernameLabel: UILabel!
	fileprivate(set) var textView: YYTextView!

	var width: CGFloat = 375
	fileprivate var postContent: PostContent?
	var trailData: PostTrailData? {
		didSet {
			avatarImageView.image = UIImage(named: "Placeholder")

			guard let trailData = trailData else {
				usernameLabel.text = nil
				content = nil
				return
			}

			PINCache.shared.object(forKeyAsync: "avatar:\(trailData.username)") { _, _, object in
				if let data = object as? Data {
					self.avatarLoadQueue.async {
						let image = UIImage(data: data)
						DispatchQueue.main.async {
							self.avatarImageView.image = image
						}
					}
				} else {
					TMAPIClient.sharedInstance().avatar(trailData.username, size: 80) { response, error in
						if let error = error {
							print(error)
						} else {
							guard let data = response as? Data else {
								return
							}
							PINCache.shared.setObject(data, forKey: "avatar:\(trailData.username)")
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

			usernameLabel.text = trailData.username
			content = trailData.content.htmlStringWithTumblrStyle(width)
		}
	}
	var content: String? {
		didSet {
			if let content = content {
				let data = content.data(using: String.Encoding.utf8)!
				var postContent = PostContent(htmlData: data)
				postContent.contentURLS().forEach { contentURL in
					let imageView = FLAnimatedImageView()
					imageView.backgroundColor = UIColor.purple
					imageView.pin_setImage(from: contentURL) { result in
						let size = result.image?.size ?? .zero // ?? result.animatedImage?.size ?? .zero
						let width = self.widthForURL?(contentURL.absoluteString) ?? min(size.width, self.width - 20)
						let scaledSize = CGSize(width: width, height: floor(size.height * width / size.width))

						postContent.setImageView(imageView, withSize: scaledSize, forAttachmentURL: contentURL)

						self.textView.attributedText = postContent.attributedStringForDisplayWithLinkHandler { url in
							self.linkHandler?(url)
						}
						self.widthDidChange?(contentURL.absoluteString, scaledSize.width, scaledSize.height, imageView)
					}
				}
				textView.attributedText = postContent.attributedStringForDisplayWithLinkHandler { url in
					self.linkHandler?(url)
				}
				usernameLabel.superview?.isHidden = (postContent.attributedString.string.characters.count == 0)
			} else {
				textView.attributedText = NSAttributedString(string: "")
				usernameLabel.superview?.isHidden = true
			}
		}
	}

	var linkHandler: ((URL) -> Void)?
	var usernameTapHandler: ((String) -> Void)?
	var widthDidChange: ((_ url: String, _ width: CGFloat, _ height: CGFloat, _ imageView: FLAnimatedImageView) -> Void)?
	var widthForURL: ((_ url: String) -> CGFloat?)?
	var imageViewForURL: ((_ url: String) -> FLAnimatedImageView?)?

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
		let usernameButton = UIButton(type: .system)

		avatarImageView = UIImageView()
		usernameLabel = UILabel()
		textView = YYTextView()

		usernameContainerView.backgroundColor = UIColor.white

		usernameButton.addTarget(self, action: #selector(ContentTableViewCell.handleUsernameTap(_:)), for: .touchUpInside)

		avatarImageView.clipsToBounds = true
		avatarImageView.contentMode = .scaleAspectFit
		avatarImageView.layer.cornerRadius = 4

		usernameLabel.font = UIFont.boldSystemFont(ofSize: 16)

		textView.isEditable = false
		textView.isScrollEnabled = false
		textView.textContainerInset = UIEdgeInsets.zero
		textView.clipsToBounds = true

		usernameContainerView.addSubview(avatarImageView)
		usernameContainerView.addSubview(usernameLabel)
		usernameContainerView.addSubview(usernameButton)
		contentView.addSubview(textView)
		contentView.addSubview(usernameContainerView)

		constrain([usernameContainerView, usernameButton, avatarImageView, usernameLabel, textView, contentView]) { views in
			let usernameContainerView = views[0]
			let usernameButton = views[1]
			let avatarImageView = views[2]
			let usernameLabel = views[3]
			let textView = views[4]
			let contentView = views[5]

			usernameContainerView.top == contentView.top
			usernameContainerView.right <= contentView.right
			usernameContainerView.left == contentView.left
			usernameContainerView.height == 32

			usernameButton.edges == usernameContainerView.edges

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

    func handleUsernameTap(_ sender: AnyObject) {
        guard let username = trailData?.username else {
            return
        }
        usernameTapHandler?(username)
    }
}
