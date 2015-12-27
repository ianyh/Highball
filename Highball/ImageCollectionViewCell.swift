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
    
    var onTapHandler: (() -> ())?

    var contentWidth: CGFloat? {
        didSet {
            self.loadPhoto()
        }
    }
    var photo: PostPhoto? {
        didSet {
            self.loadPhoto()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    func setUpCell() {
        self.scrollView = UIScrollView()
        self.imageView = FLAnimatedImageView()
        self.failedImageView = UIImageView()

        self.scrollView.delegate = self
        self.scrollView.maximumZoomScale = 5.0
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false

        self.imageView.contentMode = UIViewContentMode.ScaleAspectFit

        self.failedImageView.image = FAKIonIcons.iosCameraOutlineIconWithSize(50).imageWithSize(CGSize(width: 50, height: 50))

        self.contentView.addSubview(self.scrollView)
        self.scrollView.addSubview(self.imageView)
        self.scrollView.addSubview(self.failedImageView)

        constrain(self.scrollView, self.contentView) { scrollView, contentView in
            scrollView.edges == contentView.edges; return
        }

        constrain(self.failedImageView, self.imageView) { failedImageView, imageView in
            failedImageView.edges == imageView.edges; return
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("onTap:"))

        self.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let imageSize = self.contentView.frame.size
        let imageFrame = CGRect(origin: CGPointZero, size: imageSize)

        self.imageView.frame = imageFrame
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.imageView.animatedImage = nil
        self.failedImageView.hidden = true
        self.scrollView.zoomScale = 1
        self.centerScrollViewContents()
    }

    func loadPhoto() {
        if let photo = self.photo {
            if let contentWidth = self.contentWidth {
                let imageURL = photo.urlWithWidth(contentWidth)
                self.imageView.pin_setImageFromURL(imageURL) { result in
                    self.failedImageView.hidden = result.error == nil; return
                }
            }
        }
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.centerScrollViewContents()
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func centerScrollViewContents() {
        let boundsSize = self.scrollView.bounds.size;
        var contentsFrame = self.imageView.frame;
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0;
        } else {
            contentsFrame.origin.x = 0.0;
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0;
        } else {
            contentsFrame.origin.y = 0.0;
        }

        self.imageView.frame = contentsFrame
    }

    func onTap(recognizer: UITapGestureRecognizer) {
        if let handler = self.onTapHandler {
            handler()
        }
    }
}
