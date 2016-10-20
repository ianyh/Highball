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
	fileprivate var attachments: [String: Attachment] = [:]

	public init(htmlData: Data) {
		let stringBuilderOptions = [DTDefaultHeadIndent: 0, DTDefaultFirstLineHeadIndent: 0, DTDocumentPreserveTrailingSpaces: false, DTUseiOS6Attributes: true] as [String : Any]
		let htmlStringBuilder = DTHTMLAttributedStringBuilder(html: htmlData, options: stringBuilderOptions, documentAttributes: nil)
		attributedString = (htmlStringBuilder?.generatedAttributedString().attributedStringByTrimmingNewlines())!
	}

	public func attributedStringForDisplayWithLinkHandler(_ linkHandler: ((URL) -> ())?) -> NSAttributedString {
		let mutableAttributedString = attributedString.mutableCopy() as! NSMutableAttributedString
		let entireStringRange = NSMakeRange(0, attributedString.length)
		let options = NSAttributedString.EnumerationOptions.reverse
		attributedString.enumerateAttributes(in: entireStringRange, options: options) { attributes, range, stop in
			if let imageAttachment = attributes[NSAttachmentAttributeName] as? DTImageTextAttachment {
				if let attachment = self.attachments[imageAttachment.contentURL.absoluteString] {
					attachment.imageView.frame = CGRect(origin: CGPoint.zero, size: attachment.size)
					let attachmentViewString = NSMutableAttributedString.yy_attachmentString(
						withContent: attachment.imageView,
						contentMode: .left,
						attachmentSize: attachment.size,
						alignTo: UIFont.systemFont(ofSize: 16),
						alignment: .center
					)
					mutableAttributedString.replaceCharacters(in: range, with: attachmentViewString)
				} else {
					mutableAttributedString.replaceCharacters(in: range, with: "")
				}
			} else if let link = attributes[NSLinkAttributeName] {
				let linkURL = (link as? URL) ?? URL(string: link as! String)!

				mutableAttributedString.yy_setUnderlineStyle(.styleSingle, range: range)
				mutableAttributedString.yy_setTextHighlight(
					range,
					color: UIColor.blue,
					backgroundColor: nil,
					userInfo: nil,
					tapAction: { containerView, text, range, rect in
						linkHandler?(linkURL)
					},
					longPressAction: nil
				)
			}
		}

		return mutableAttributedString
	}

	public func contentURLS() -> [URL] {
		let entireStringRange = NSMakeRange(0, attributedString.length)
		let options = NSAttributedString.EnumerationOptions()
		var urls: [URL] = []
		attributedString.enumerateAttributes(in: entireStringRange, options: options) { attributes, range, stop in
			if let imageAttachment = attributes[NSAttachmentAttributeName] as? DTImageTextAttachment {
				urls.append(imageAttachment.contentURL)
			}
		}
		return urls
	}

	mutating public func setImageView(_ imageView: FLAnimatedImageView, withSize size: CGSize, forAttachmentURL url: URL) {
		attachments[url.absoluteString] = Attachment(imageView: imageView, size: size)
	}
}
