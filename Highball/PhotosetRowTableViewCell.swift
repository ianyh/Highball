//
//  PhotosetRowTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PhotosetRowTableViewCell: UITableViewCell {

    var imageViews: Array<UIImageView>?
    
    var contentWidth: CGFloat? {
        didSet {
            self.updateImages()
        }
    }
    var images: Array<PostPhoto>? {
        didSet {
            self.updateImages()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        if let imageViews = self.imageViews {
            for imageView in imageViews {
                imageView.sd_cancelCurrentImageLoad()
                imageView.sd_cancelCurrentAnimationImagesLoad()
                imageView.image = nil
                imageView.removeFromSuperview()
            }
        }
    }

    func updateImages() {
        if let images = self.images {
            if let contentWidth = self.contentWidth {
                if let imageViews = self.imageViews {
                    for imageView in imageViews {
                        imageView.sd_cancelCurrentImageLoad()
                        imageView.sd_cancelCurrentAnimationImagesLoad()
                        imageView.image = nil
                        imageView.removeFromSuperview()
                    }
                }
                
                let widthRatio: Float = 1.0 / Float(images.count)
                var imageViews = Array<UIImageView>()
                var lastImageView: UIImageView?
                for image in images {
                    let imageView = UIImageView()
                    let imageURL = image.urlWithWidth(contentWidth)
                    
                    self.contentView.addSubview(imageView)
                    
                    if let leftImageView = lastImageView {
                        layout2(imageView, leftImageView) { view, leftView in
                            view.left == leftView.right
                            view.height == leftView.height
                            view.centerY == leftView.centerY
                            view.width == leftView.width
                        }
                    } else {
                        layout2(imageView, self.contentView) { view, contentView in
                            view.left == contentView.left
                            view.top == contentView.top
                            view.bottom == contentView.bottom
                            view.width == (contentView.width * widthRatio)
                        }
                    }

                    imageView.sd_cancelCurrentImageLoad()
                    imageView.sd_cancelCurrentAnimationImagesLoad()
                    imageView.sd_setImageWithURL(imageURL, placeholderImage: UIImage(named: "Placeholder"))
                    
                    lastImageView = imageView
                }
                
                self.imageViews = imageViews
            }
        }
    }

}
