//
//  PostContent.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 4/9/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import DTCoreText
import FLAnimatedImage
import Foundation
import YYText

private struct Attachment {
	let imageView: FLAnimatedImageView
	let size: CGSize
}

public struct PostContent {
	public let attributedString: NSAttributedString
	private var attachments: [String: Attachment] = [:]

	public init(htmlData: NSData) {
		let stringBuilderOptions = [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0, DTDocumentPreserveTrailingSpaces: false, DTUseiOS6Attributes: true]
		let htmlStringBuilder = DTHTMLAttributedStringBuilder(HTML: htmlData, options: stringBuilderOptions, documentAttributes: nil)
		attributedString = htmlStringBuilder.generatedAttributedString().attributedStringByTrimmingNewlines()
	}

	public func attributedStringForDisplayWithLinkHandler(linkHandler: ((NSURL) -> ())?) -> NSAttributedString {
		let mutableAttributedString = attributedString.mutableCopy() as! NSMutableAttributedString
		let entireStringRange = NSMakeRange(0, attributedString.length)
		let options = NSAttributedStringEnumerationOptions.Reverse
		attributedString.enumerateAttributesInRange(entireStringRange, options: options) { attributes, range, stop in
			if let imageAttachment = attributes[NSAttachmentAttributeName] as? DTImageTextAttachment {
				if let attachment = self.attachments[imageAttachment.contentURL.absoluteString] {
					attachment.imageView.frame = CGRect(origin: CGPoint.zero, size: attachment.size)
					let attachmentViewString = NSMutableAttributedString.yy_attachmentStringWithContent(
						attachment.imageView,
						contentMode: .Left,
						attachmentSize: attachment.size,
						alignToFont: UIFont.systemFontOfSize(16),
						alignment: .Center
					)
					mutableAttributedString.replaceCharactersInRange(range, withAttributedString: attachmentViewString)
				} else {
					mutableAttributedString.replaceCharactersInRange(range, withString: "")
				}
			} else if let link = attributes[NSLinkAttributeName] {
				let linkURL = (link as? NSURL) ?? NSURL(string: link as! String)!

				mutableAttributedString.yy_setUnderlineStyle(.StyleSingle, range: range)
				mutableAttributedString.yy_setTextHighlightRange(
					range,
					color: UIColor.blueColor(),
					backgroundColor: nil,
					tapAction: { containerView, text, range, rect in
						linkHandler?(linkURL)
					}
				)
			}
		}

		return mutableAttributedString
	}

	public func contentURLS() -> [NSURL] {
		let entireStringRange = NSMakeRange(0, attributedString.length)
		let options = NSAttributedStringEnumerationOptions()
		var urls: [NSURL] = []
		attributedString.enumerateAttributesInRange(entireStringRange, options: options) { attributes, range, stop in
			if let imageAttachment = attributes[NSAttachmentAttributeName] as? DTImageTextAttachment {
				urls.append(imageAttachment.contentURL)
			}
		}
		return urls
	}

	mutating public func setImageView(imageView: FLAnimatedImageView, withSize size: CGSize, forAttachmentURL url: NSURL) {
		attachments[url.absoluteString] = Attachment(imageView: imageView, size: size)
	}
}
