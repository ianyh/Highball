//
//  PhotosetRowTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import FLAnimatedImage
import FontAwesomeKit
import UIKit
import WCFastCell

class PhotosetRowTableViewCell: WCFastCell {
	var imageViews: Array<FLAnimatedImageView>?
	var failedImageViews: Array<UIImageView>?
	var shareHandler: ((UIImage) -> ())?

	var contentWidth: CGFloat! = 0
	var images: Array<PostPhoto>? {
		didSet {
			dispatch_async(dispatch_get_main_queue()) {
				self.updateImages()
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		clearImages()
	}

	private func updateImages() {
		guard let images = images, contentWidth = contentWidth else {
			return
		}

		clearImages()

		let totalWidth = images.map { $0.widthToHeightRatio! }.reduce(0, combine: +)
		let lastImageIndex = images.count - 1
		var imageViews = Array<FLAnimatedImageView>()
		var failedImageViews = Array<UIImageView>()
		var lastImageView: UIImageView?
		for (index, image) in images.enumerate() {
			let widthPortion = image.widthToHeightRatio! / totalWidth
			let imageView = FLAnimatedImageView()
			let failedImageView = UIImageView()
			let imageURL = image.urlWithWidth(contentWidth)

			imageView.contentMode = .ScaleAspectFill
			imageView.image = nil
			imageView.userInteractionEnabled = true

			failedImageView.backgroundColor = UIColor.whiteColor()
			failedImageView.contentMode = .Center
			failedImageView.hidden = true
			failedImageView.image = FAKIonIcons.iosCameraOutlineIconWithSize(50).imageWithSize(CGSize(width: 50, height: 50))

			contentView.addSubview(imageView)
			contentView.addSubview(failedImageView)

			constrain(failedImageView, imageView) { failedImageView, imageView in
				failedImageView.edges == imageView.edges
			}

			if let leftImageView = lastImageView {
				if index == lastImageIndex {
					constrain(imageView, leftImageView, contentView) { imageView, leftImageView, contentView in
						imageView.centerY == leftImageView.centerY
						imageView.left == leftImageView.right
						imageView.right == contentView.right
						imageView.height == leftImageView.height
					}
				} else {
					constrain(imageView, leftImageView, contentView) { imageView, leftImageView, contentView in
						imageView.centerY == leftImageView.centerY
						imageView.left == leftImageView.right
						imageView.height == leftImageView.height
						imageView.width == contentView.width * CGFloat(widthPortion)
					}
				}
			} else if images.count == 1 {
				constrain(imageView, contentView) { imageView, contentView in
					imageView.left == contentView.left
					imageView.top == contentView.top
					imageView.bottom == contentView.bottom
					imageView.right == contentView.right
				}
			} else {
				constrain(imageView, contentView) { imageView, contentView in
					imageView.left == contentView.left
					imageView.top == contentView.top
					imageView.bottom == contentView.bottom
					imageView.width == contentView.width * CGFloat(widthPortion)
				}
			}

			imageView.pin_setImageFromURL(imageURL) { result in
				if result.resultType != .MemoryCache {
					imageView.alpha = 0
					UIView.animateWithDuration(
						0.5,
						delay: 0.1,
						options: .AllowUserInteraction,
						animations: { imageView.alpha = 1.0 },
						completion: nil
					)
				}
				failedImageView.hidden = result.error == nil
			}

			lastImageView = imageView

			imageViews.append(imageView)
			failedImageViews.append(failedImageView)
		}

		self.imageViews = imageViews
		self.failedImageViews = failedImageViews
	}

	private func clearImages() {
		imageViews?.forEach {
			$0.pin_cancelImageDownload()
			$0.image = nil
			$0.animatedImage = nil
			$0.removeFromSuperview()
		}

		failedImageViews?.forEach {
			$0.removeFromSuperview()
		}

		imageViews = nil
		failedImageViews = nil
	}

	func imageAtPoint(point: CGPoint) -> UIImage? {
		guard let view = self.hitTest(point, withEvent: nil), imageView = view as? UIImageView else {
			return nil
		}

		return imageView.image
	}

	func cancelDownloads() {
		clearImages()
	}
}
