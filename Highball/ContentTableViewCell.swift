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
import WCFastCell

class ContentTableViewCell: WCFastCell, DTAttributedTextContentViewDelegate, DTLazyImageViewDelegate {
	private(set) var usernameLabel: UILabel!
	private(set) var contentTextView: DTAttributedTextContentView!
	var username: String? {
		didSet {
			usernameLabel.text = username
		}
	}
	var content: String? {
		didSet {
			if let content = content {
				let data = content.dataUsingEncoding(NSUTF8StringEncoding)
				let htmlStringBuilder = DTHTMLAttributedStringBuilder(HTML: data, options: [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0], documentAttributes: nil)
				let attributedString = htmlStringBuilder.generatedAttributedString()
				contentTextView.attributedString = attributedString
			} else {
				contentTextView.attributedString = NSAttributedString()
			}
		}
	}

	var linkHandler: ((NSURL) -> ())?
	var heightDidChange: ((delta: CGFloat) -> ())?

	override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	func setUpCell() {
		usernameLabel = UILabel()
		contentTextView = DTAttributedTextContentView()

		usernameLabel.backgroundColor = UIColor.blackColor()
		usernameLabel.font = UIFont.boldSystemFontOfSize(16)
		usernameLabel.textColor = UIColor.whiteColor()

		contentTextView.delegate = self

		contentView.addSubview(usernameLabel)
		contentView.addSubview(contentTextView)

		constrain(usernameLabel, contentTextView, contentView) { usernameLabel, contentTextView, contentView in
			usernameLabel.top == contentView.top + 4
			usernameLabel.right == contentView.right - 10
			usernameLabel.left == contentView.left + 10
			usernameLabel.height == 24

			contentTextView.top == usernameLabel.bottom + 4
			contentTextView.right == contentView.right - 10
			contentTextView.bottom == contentView.bottom - 4
			contentTextView.left == contentView.left + 10
		}
	}

	override func prepareForReuse() {
		username = nil
		content = nil
	}

	func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, viewForAttachment attachment: DTTextAttachment!, frame: CGRect) -> UIView! {
		return nil
		if let attachment = attachment as? DTImageTextAttachment {
			let imageView = DTLazyImageView(frame: frame)
			imageView.delegate = self

			// url for deferred loading
			imageView.url = attachment.contentURL
			return imageView
		}
		return nil
	}

	func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, shouldDrawBackgroundForTextBlock textBlock: DTTextBlock!, frame: CGRect, context: CGContext!, forLayoutFrame layoutFrame: DTCoreTextLayoutFrame!) -> Bool {
		let rect = CGRect(x: frame.origin.x, y: frame.origin.y, width: 2, height: frame.height)
		let path = UIBezierPath(rect: rect)

		CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
		CGContextAddPath(context, path.CGPath)
		CGContextFillPath(context)

		return false
	}

	func lazyImageView(lazyImageView: DTLazyImageView!, didChangeImageSize size: CGSize) {
		let url = lazyImageView.url
		let pred = NSPredicate(format: "contentURL == %@", url)
		var delta: CGFloat = 0

		// update all attachments that matching this URL
		for attachment in contentTextView.layoutFrame.textAttachmentsWithPredicate(pred) as! [DTTextAttachment] {
			let originalSize = attachment.originalSize
			delta += (size.height - originalSize.height)
			attachment.originalSize = size
		}

		// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
		contentTextView.layouter = nil

		// here we're layouting the entire string,
		// might be more efficient to only relayout the paragraphs that contain these attachments
		contentTextView.relayoutText()

		heightDidChange?(delta: delta)
	}
}
