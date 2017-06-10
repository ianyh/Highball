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
	var imageViews: [FLAnimatedImageView]?
	var failedImageViews: [UIImageView]?
	var shareHandler: ((UIImage) -> Void)?

	var contentWidth: CGFloat! = 0
	var images: [PostPhoto]? {
		didSet {
			DispatchQueue.main.async {
				self.updateImages()
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		clearImages()
	}

	fileprivate func updateImages() {
		guard let images = images, let contentWidth = contentWidth else {
			return
		}

		clearImages()

		let totalWidth = images.map { $0.widthToHeightRatio! }.reduce(0, +)
		let lastImageIndex = images.count - 1
		var imageViews = [FLAnimatedImageView]()
		var failedImageViews = [UIImageView]()
		var lastImageView: UIImageView?
		for (index, image) in images.enumerated() {
			let widthPortion = image.widthToHeightRatio! / totalWidth
			let imageView = FLAnimatedImageView()
			let failedImageView = UIImageView()
			let imageURL = image.urlWithWidth(contentWidth)

			imageView.contentMode = .scaleAspectFill
			imageView.image = nil
			imageView.isUserInteractionEnabled = true

			failedImageView.backgroundColor = UIColor.white
			failedImageView.contentMode = .center
			failedImageView.isHidden = true
			failedImageView.image = FAKIonIcons.iosCameraOutlineIcon(withSize: 50).image(with: CGSize(width: 50, height: 50))

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

			imageView.pin_setImage(from: imageURL) { result in
				if result.resultType != .memoryCache {
					imageView.alpha = 0
					UIView.animate(
						withDuration: 0.5,
						delay: 0.1,
						options: .allowUserInteraction,
						animations: { imageView.alpha = 1.0 },
						completion: nil
					)
				}
				failedImageView.isHidden = result.error == nil
			}

			lastImageView = imageView

			imageViews.append(imageView)
			failedImageViews.append(failedImageView)
		}

		self.imageViews = imageViews
		self.failedImageViews = failedImageViews
	}

	fileprivate func clearImages() {
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

	func imageAtPoint(_ point: CGPoint) -> UIImage? {
		guard let view = self.hitTest(point, with: nil), let imageView = view as? UIImageView else {
			return nil
		}

		return imageView.image
	}

	func cancelDownloads() {
		clearImages()
	}
}
