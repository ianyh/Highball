//
//  ImageCollectionViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import FLAnimatedImage
import FontAwesomeKit
import PINRemoteImage
import UIKit

class ImageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
	var scrollView: UIScrollView!
	var imageView: FLAnimatedImageView!
	var failedImageView: UIImageView!

	var onTapHandler: (() -> Void)?

	var contentWidth: CGFloat? {
		didSet {
			loadPhoto()
		}
	}
	var photo: PostPhoto? {
		didSet {
			loadPhoto()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setUpCell()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpCell()
	}

	func setUpCell() {
		scrollView = UIScrollView()
		imageView = FLAnimatedImageView()
		failedImageView = UIImageView()

		scrollView.delegate = self
		scrollView.maximumZoomScale = 5.0
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false

		imageView.contentMode = .scaleAspectFit

		failedImageView.image = FAKIonIcons.iosCameraOutlineIcon(withSize: 50).image(with: CGSize(width: 50, height: 50))

		contentView.addSubview(scrollView)
		scrollView.addSubview(imageView)
		scrollView.addSubview(failedImageView)

		constrain(scrollView, contentView) { scrollView, contentView in
			scrollView.edges == contentView.edges
		}

		constrain(failedImageView, imageView) { failedImageView, imageView in
			failedImageView.edges == imageView.edges
		}

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImageCollectionViewCell.onTap(_:)))

		addGestureRecognizer(tapGestureRecognizer)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let imageSize = contentView.frame.size
		let imageFrame = CGRect(origin: CGPoint.zero, size: imageSize)

		imageView.frame = imageFrame
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		imageView.image = nil
		imageView.animatedImage = nil
		failedImageView.isHidden = true
		scrollView.zoomScale = 1
		centerScrollViewContents()
	}

	func loadPhoto() {
		guard let photo = photo,
			let contentWidth = contentWidth
		else {
			return
		}

		let imageURL = photo.urlWithWidth(contentWidth)
		imageView.pin_setImage(from: imageURL, completion: { result in
			self.failedImageView.isHidden = result.error == nil
		})
	}

	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		centerScrollViewContents()
	}

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}

	func centerScrollViewContents() {
		let boundsSize = scrollView.bounds.size
		var contentsFrame = imageView.frame

		if contentsFrame.size.width < boundsSize.width {
			contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
		} else {
			contentsFrame.origin.x = 0.0
		}

		if contentsFrame.size.height < boundsSize.height {
			contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
		} else {
			contentsFrame.origin.y = 0.0
		}

		imageView.frame = contentsFrame
	}

	func onTap(_ recognizer: UITapGestureRecognizer) {
		onTapHandler?()
	}
}
