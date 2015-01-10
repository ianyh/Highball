//
//  TagsTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/4/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit

class TagsTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let tagCollectionViewCellIdentifier = "tagCollectionViewCellIdentifier"
    private class TagCollectionViewCell: UICollectionViewCell {
        private var tagLabel: UILabel!

        class func widthForTag(tag: String) -> CGFloat {
            let constrainedSize = CGSize(width: CGFloat.max, height: CGFloat.max)
            let attributedTag = NSAttributedString(string: tag, attributes: [ NSFontAttributeName : UIFont.systemFontOfSize(12) ])
            let tagRect = attributedTag.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
            
            return ceil(tagRect.size.width)
        }

        required override init() {
            super.init()
            self.setUpCell()
        }

        required init(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.setUpCell()
        }

        func setUpCell() {
            self.tagLabel = UILabel()
            self.tagLabel.font = UIFont.systemFontOfSize(12)

            self.contentView.addSubview(self.tagLabel)

            layout(self.tagLabel, self.contentView) { tagLabel, contentView in
                tagLabel.edges == contentView.edges; return
            }
        }
    }

    private var collectionView: UICollectionView!
    var tags: Array<String>? {
        didSet {
            if let collectionView = self.collectionView {
                collectionView.reloadData()
            }
        }
    }
    
    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }
    
    func setUpCell() {
        self.collectionView = UICollectionView()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.collectionView.registerClass(TagCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: tagCollectionViewCellIdentifier)

        self.contentView.addSubview(self.collectionView)
        
        layout(self.collectionView, self.contentView) { collectionView, contentView in
            collectionView.edges == contentView.edges; return
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let tags = self.tags {
            return tags.count
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(tagCollectionViewCellIdentifier, forIndexPath: indexPath) as TagCollectionViewCell
        let tag = self.tags![indexPath.row]

        cell.tagLabel.text = tag

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let tag = self.tags![indexPath.row]

        return CGSize(width: TagCollectionViewCell.widthForTag(tag), height: collectionView.frame.size.height)
    }
}
