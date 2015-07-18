//
//  PhotosetRowTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import WCFastCell
import FontAwesomeKit

class PhotosetRowTableViewCell: WCFastCell {
    var imageViews: Array<FLAnimatedImageView>?
    var failedImageViews: Array<UIImageView>?
    var shareHandler: ((UIImage) -> ())?
    
    var contentWidth: CGFloat! = 0
    var images: Array<PostPhoto>? {
        didSet {
            dispatch_async(dispatch_get_main_queue(), {
                self.updateImages()
            })
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.clearImages()
    }

    private func updateImages() {
        if let images = self.images {
            if let contentWidth = self.contentWidth {
                self.clearImages()

                let totalWidth = images.map { $0.widthToHeightRatio! }.reduce(0, combine: +)
                let lastImageIndex = images.count - 1
                var imageViews = Array<FLAnimatedImageView>()
                var failedImageViews = Array<UIImageView>()
                var lastImageView: UIImageView?
                for (index, image) in enumerate(images) {
                    let widthPortion = image.widthToHeightRatio! / totalWidth
                    let imageView = FLAnimatedImageView()
                    let failedImageView = UIImageView()
                    let imageURL = image.urlWithWidth(contentWidth)

                    imageView.image = nil
                    imageView.backgroundColor = UIColor.lightGrayColor()
                    imageView.userInteractionEnabled = true
                    imageView.contentMode = UIViewContentMode.ScaleAspectFill

                    failedImageView.contentMode = UIViewContentMode.Center
                    failedImageView.hidden = true
                    failedImageView.image = FAKIonIcons.iosCameraOutlineIconWithSize(50).imageWithSize(CGSize(width: 50, height: 50))

                    self.contentView.addSubview(imageView)
                    self.contentView.addSubview(failedImageView)

                    layout(failedImageView, imageView) { failedImageView, imageView in
                        failedImageView.edges == imageView.edges; return
                    }

                    if let leftImageView = lastImageView {
                        if index == lastImageIndex {
                            layout(imageView, leftImageView, self.contentView) { imageView, leftImageView, contentView in
                                imageView.centerY == leftImageView.centerY
                                imageView.left == leftImageView.right
                                imageView.right == contentView.right
                                imageView.height == leftImageView.height
                            }
                        } else {
                            layout(imageView, leftImageView, self.contentView) { imageView, leftImageView, contentView in
                                imageView.centerY == leftImageView.centerY
                                imageView.left == leftImageView.right
                                imageView.height == leftImageView.height
                                imageView.width == contentView.width * widthPortion
                            }
                        }
                    } else if images.count == 1 {
                        layout(imageView, self.contentView) { imageView, contentView in
                            imageView.left == contentView.left
                            imageView.top == contentView.top
                            imageView.bottom == contentView.bottom
                            imageView.right == contentView.right
                        }
                    } else {
                        layout(imageView, self.contentView) { imageView, contentView in
                            imageView.left == contentView.left
                            imageView.top == contentView.top
                            imageView.bottom == contentView.bottom
                            imageView.width == contentView.width * widthPortion
                        }
                    }

                    imageView.pin_setImageFromURL(imageURL) { result in
                        failedImageView.hidden = result.error == nil; return
                    }

                    lastImageView = imageView

                    imageViews.append(imageView)
                    failedImageViews.append(failedImageView)
                }
                
                self.imageViews = imageViews
                self.failedImageViews = failedImageViews
            }
        }
    }

    private func clearImages() {
        if let imageViews = self.imageViews {
            for imageView in imageViews {
                imageView.image = nil
                imageView.animatedImage = nil
                imageView.removeFromSuperview()
            }
        }

        if let failedImageViews = self.failedImageViews {
            for imageView in failedImageViews {
                imageView.removeFromSuperview()
            }
        }

        self.imageViews = nil
        self.failedImageViews = nil
    }

    func imageAtPoint(point: CGPoint) -> UIImage? {
        if let imageView = self.hitTest(point, withEvent: nil) as? UIImageView {
            return imageView.image
        }
        return nil
    }

    func cancelDownloads() {
        self.clearImages()
    }
}
