//
//  TagsTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/4/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography

protocol TagsTableViewCellDelegate {
    func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String)
}

class TagsTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private class TagCollectionViewCell: UICollectionViewCell {
        private var tagLabel: UILabel!

        class func widthForTag(tag: String) -> CGFloat {
            let constrainedSize = CGSize(width: CGFloat.max, height: CGFloat.max)
            let attributedTag = NSAttributedString(string: tag, attributes: [ NSFontAttributeName : UIFont.systemFontOfSize(14) ])
            let tagRect = attributedTag.boundingRectWithSize(constrainedSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)

            return ceil(tagRect.size.width)
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpCell()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }

        func setUpCell() {
            tagLabel = UILabel()
            tagLabel.font = UIFont.systemFontOfSize(14)
            tagLabel.textColor = UIColor.grayColor()

            contentView.addSubview(tagLabel)

            constrain(tagLabel, contentView) { tagLabel, contentView in
                tagLabel.edges == contentView.edges
            }
        }
    }

    private var collectionView: UICollectionView!
    var delegate: TagsTableViewCellDelegate?
    var tags: [String]? {
        didSet {
            collectionView.contentOffset = CGPoint(x: collectionView.contentInset.left, y: 0)
        }
    }

    override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func setUpCell() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .Horizontal
        collectionViewLayout.minimumInteritemSpacing = 5

        collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        collectionView.registerClass(TagCollectionViewCell.self, forCellWithReuseIdentifier: TagCollectionViewCell.cellIdentifier)

        contentView.addSubview(collectionView)

        constrain(collectionView, contentView) { collectionView, contentView in
            collectionView.edges == contentView.edges
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TagCollectionViewCell.cellIdentifier, forIndexPath: indexPath) as! TagCollectionViewCell
        let tag = tags![indexPath.row]

        cell.tagLabel.text = tag

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let tag = tags![indexPath.row]

        return CGSize(width: TagCollectionViewCell.widthForTag(tag), height: collectionView.frame.height)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.tagsTableViewCell(self, didSelectTag: self.tags![indexPath.row])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        collectionView.reloadData()
    }
}
