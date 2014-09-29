//
//  PhotosetRowTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PhotosetRowTableViewCell: WCFastCell {

    var imageViews: Array<FLAnimatedImageView>?
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
                imageView.removeFromSuperview()
            }
        }
    }

    func updateImages() {
        if let images = self.images {
            if let contentWidth = self.contentWidth {
                if let imageViews = self.imageViews {
                    for imageView in imageViews {
                        imageView.removeFromSuperview()
                    }
                }

                let imageManager = SDWebImageManager.sharedManager()
                let imageDownloader = SDWebImageDownloader.sharedDownloader()
                let widthRatio: Float = 1.0 / Float(images.count)
                var imageViews = Array<FLAnimatedImageView>()
                var lastImageView: UIImageView?
                for image in images {
                    let imageView = FLAnimatedImageView()
                    let imageURL = image.urlWithWidth(contentWidth)
                    let cacheKey = imageManager.cacheKeyForURL(imageURL)
                    
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

                    imageView.sd_setImageWithURL(imageURL, placeholderImage: UIImage(named: "Placeholder"))
                    imageView.image = UIImage(named: "Placeholder")
                    imageView.userInteractionEnabled = true

                    if imageURL.pathExtension == "gif" {
                        if let data = TMCache.sharedCache().objectForKey(imageURL.absoluteString) as? NSData {
                            imageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
                        } else {
                            imageDownloader.downloadImageWithURL(imageURL, options: SDWebImageDownloaderOptions.UseNSURLCache, progress: nil, completed: { (image, data, error, finished) -> Void in
                                if finished && error == nil {
                                    imageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
                                    TMCache.sharedCache().setObject(data, forKey: imageURL.absoluteString)
                                }
                            })
                        }
                    } else {
                        imageView.sd_setImageWithURL(imageURL, placeholderImage: UIImage(named: "Placeholder"))
                    }
                    
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
