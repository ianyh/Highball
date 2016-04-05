//
//  ContentTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/28/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import DTCoreText
import FLAnimatedImage
import PINCache
import PINRemoteImage
import TMTumblrSDK
import WCFastCell

class ContentTableViewCell: WCFastCell, DTAttributedTextContentViewDelegate {
	private let avatarLoadQueue = dispatch_queue_create("avatarLoadQueue", nil)
	private(set) var avatarImageView: UIImageView!
	private(set) var usernameLabel: UILabel!
	private(set) var contentTextView: DTAttributedTextContentView!
	var width: CGFloat = 375
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
			content = trailData.content.htmlStringWithTumblrStyle(0)
		}
	}
	var content: String? {
		didSet {
			if let content = content {
				let data = content.dataUsingEncoding(NSUTF8StringEncoding)
				let stringBuilderOptions = [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0, DTDocumentPreserveTrailingSpaces: false, DTUseiOS6Attributes: true]
				let htmlStringBuilder = DTHTMLAttributedStringBuilder(HTML: data, options: stringBuilderOptions, documentAttributes: nil)
				let attributedString = htmlStringBuilder.generatedAttributedString().attributedStringByTrimmingNewlines()
				contentTextView.attributedString = attributedString
				usernameLabel.superview?.hidden = (attributedString.string.characters.count == 0)
			} else {
				contentTextView.attributedString = NSAttributedString(string: "")
				usernameLabel.superview?.hidden = true
			}
		}
	}

	var linkHandler: ((NSURL) -> ())?
	var widthDidChange: ((url: String, width: CGFloat, height: CGFloat) -> ())?
	var widthForURL: ((url: String) -> CGFloat?)?

	override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	func setUpCell() {
		let usernameContainerView = UIView()

		avatarImageView = UIImageView()
		usernameLabel = UILabel()
		contentTextView = DTAttributedTextContentView()

		usernameContainerView.backgroundColor = UIColor.whiteColor()

		avatarImageView.clipsToBounds = true
		avatarImageView.contentMode = .ScaleAspectFit
		avatarImageView.layer.cornerRadius = 4

		usernameLabel.font = UIFont.boldSystemFontOfSize(16)

		contentTextView.delegate = self
		contentTextView.edgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

		usernameContainerView.addSubview(avatarImageView)
		usernameContainerView.addSubview(usernameLabel)
		contentView.addSubview(contentTextView)
		contentView.addSubview(usernameContainerView)

		constrain([usernameContainerView, avatarImageView, usernameLabel, contentTextView, contentView]) { views in
			let usernameContainerView = views[0]
			let avatarImageView = views[1]
			let usernameLabel = views[2]
			let contentTextView = views[3]
			let contentView = views[4]

			usernameContainerView.top == contentView.top
			usernameContainerView.right <= contentView.right
			usernameContainerView.left == contentView.left
			usernameContainerView.height == 32 ~ 750

			avatarImageView.top == usernameContainerView.top + 4
			avatarImageView.bottom == usernameContainerView.bottom - 4
			avatarImageView.left == usernameContainerView.left + 6
			avatarImageView.height == 24 ~ 500
			avatarImageView.width == avatarImageView.height

			usernameLabel.top  == usernameContainerView.top + 4
			usernameLabel.right == usernameContainerView.right - 10
			usernameLabel.bottom == usernameContainerView.bottom - 4
			usernameLabel.left == avatarImageView.right + 4

			contentTextView.top == usernameContainerView.bottom
			contentTextView.right == contentView.right
			contentTextView.bottom == contentView.bottom
			contentTextView.left == contentView.left
		}

		layoutIfNeeded()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		widthDidChange = nil
		widthForURL = nil
	}

	func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, viewForAttachment attachment: DTTextAttachment!, frame: CGRect) -> UIView! {
		if let attachment = attachment as? DTImageTextAttachment {
			let imageView = FLAnimatedImageView(frame: frame)
			imageView.pin_setImageFromURL(attachment.contentURL) { result in
				if let image = result.image {
					self.imageView(imageView, withURL: attachment.contentURL, didChangeImageSize: image.size)
				} else if let animatedImage = result.animatedImage {
					self.imageView(imageView, withURL: attachment.contentURL, didChangeImageSize: animatedImage.size)
				}
			}
			return imageView
		}
		return nil
	}

	func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, shouldDrawBackgroundForTextBlock textBlock: DTTextBlock!, frame: CGRect, context: CGContext!, forLayoutFrame layoutFrame: DTCoreTextLayoutFrame!) -> Bool {
		let rect = CGRect(x: frame.origin.x, y: frame.origin.y, width: 2, height: frame.height)
		let path = UIBezierPath(rect: rect)

		CGContextSetFillColorWithColor(context, UIColor.grayColor().CGColor)
		CGContextAddPath(context, path.CGPath)
		CGContextFillPath(context)

		return false
	}

	func imageView(imageView: FLAnimatedImageView, withURL url: NSURL, didChangeImageSize size: CGSize) {
		let pred = NSPredicate(format: "contentURL == %@", url)

		// update all attachments that matching this URL
		if let attachments = contentTextView.layoutFrame?.textAttachmentsWithPredicate(pred) as? [DTTextAttachment] {
			for attachment in attachments {
				let width = widthForURL?(url: attachment.contentURL.absoluteString) ?? min(size.width, self.width - 20)
				let scaledSize = CGSize(width: width, height: floor(size.height * width / size.width))
				attachment.originalSize = size
				attachment.displaySize = scaledSize

				widthDidChange?(url: attachment.contentURL.absoluteString, width: scaledSize.width, height: scaledSize.height)
			}
		}

		// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
		contentTextView.layouter = nil

		// here we're layouting the entire string,
		// might be more efficient to only relayout the paragraphs that contain these attachments
		contentTextView.relayoutText()
	}
}
