//
//  PhotoTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/27/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

class PhotoTableViewCell: UITableViewCell {

    var imageViews: Array<UIImageView>!
    var contentLabel: UILabel!

    var post: Dictionary<String, AnyObject>? {
        didSet {
            if let post = self.post {
                let json = JSONValue(post)
                let photos = json["photos"].array!
                let photoSetLayout = json["photoset_layout"].string!.componentsSeparatedByString("")
                let photoCount = photos.count

                for imageView in self.imageViews {
                    imageView.removeFromSuperview()
                }

                while photoCount < self.imageViews.count {
                    self.imageViews.append(UIImageView())
                }

                var imageViews = self.imageViews
                var photoIndex = 0
                for (layoutRow, layoutRowString) in enumerate(photoSetLayout) {
                    var layoutRowCount = layoutRowString.toInt()!
                    var lastImageView: UIImageView?

                    while layoutRowCount > 0 {
                        let imageView = imageViews.removeAtIndex(0)
                        let imageURLString = photos[photoIndex]["original_size"]["url"].string!

                        imageView.setImageWithURL(NSURL(string: imageURLString))

                        self.contentView.addSubview(imageView)

                        if let leftImageView = lastImageView {
                            layout(imageView) { imageView in

                            }
                        }

                        layoutRowCount--
                        photoIndex++
                    }
                }
            }
        }
    }

    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        return super.init(coder: aDecoder)
    }

    func setUpCell() {
        self.imageViews = Array<UIImageView>()
    }
}
