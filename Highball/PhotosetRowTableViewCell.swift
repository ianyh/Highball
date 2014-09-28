//
//  PhotosetRowTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PhotosetRowTableViewCell: WCFastCell {

    var imageViews: Array<UIImageView>?
    var shareHandler: ((UIImage) -> ())?
    
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
                        imageView.snp_makeConstraints { (maker) -> () in
                            maker.left.equalTo(leftImageView.snp_right)
                            maker.height.equalTo(leftImageView.snp_height)
                            maker.centerY.equalTo(leftImageView.snp_centerY)
                            maker.width.equalTo(leftImageView.snp_width)
                        }
                    } else {
                        imageView.snp_makeConstraints { (maker) -> () in
                            maker.left.equalTo(self.contentView.snp_left)
                            maker.top.equalTo(self.contentView.snp_top)
                            maker.bottom.equalTo(self.contentView.snp_bottom)
                            maker.width.equalTo(self.contentView.snp_width).multipliedBy(widthRatio)
                        }
                    }

                    imageView.sd_cancelCurrentImageLoad()
                    imageView.sd_cancelCurrentAnimationImagesLoad()
                    imageView.sd_setImageWithURL(imageURL, placeholderImage: UIImage(named: "Placeholder"))
                    imageView.userInteractionEnabled = true
                    
                    lastImageView = imageView
                }
                
                self.imageViews = imageViews
            }
        }
    }

    func imageAtPoint(point: CGPoint) -> UIImage? {
        if let imageView = self.hitTest(point, withEvent: nil) as? UIImageView {
            return imageView.image
        }
        return nil
    }
}
