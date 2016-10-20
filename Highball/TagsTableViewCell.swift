//
//  TagsTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/4/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import Cartography
import UIKit

public protocol TagsTableViewCellDelegate {
	func tagsTableViewCell(_ cell: TagsTableViewCell, didSelectTag tag: String)
}

open class TagsTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	fileprivate class TagCollectionViewCell: UICollectionViewCell {
		fileprivate var tagLabel: UILabel!

		class func widthForTag(_ tag: String) -> CGFloat {
			let constrainedSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
			let attributedTag = NSAttributedString(string: tag, attributes: [ NSFontAttributeName : UIFont.systemFont(ofSize: 14) ])
			let tagRect = attributedTag.boundingRect(with: constrainedSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

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
			tagLabel.font = UIFont.systemFont(ofSize: 14)
			tagLabel.textColor = UIColor.gray

			contentView.addSubview(tagLabel)

			constrain(tagLabel, contentView) { tagLabel, contentView in
				tagLabel.edges == contentView.edges
			}
		}
	}

	fileprivate var collectionView: UICollectionView!
	open var delegate: TagsTableViewCellDelegate?
	open var tags: [String]? {
		didSet {
			collectionView.contentOffset = CGPoint(x: -collectionView.contentInset.left, y: 0)
		}
	}

	public override required init(style: UITableViewCellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpCell()
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	open func setUpCell() {
		let collectionViewLayout = UICollectionViewFlowLayout()
		collectionViewLayout.scrollDirection = .horizontal
		collectionViewLayout.minimumInteritemSpacing = 5

		collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.scrollsToTop = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.showsVerticalScrollIndicator = false
		collectionView.bounces = true
		collectionView.alwaysBounceHorizontal = true
		collectionView.backgroundColor = UIColor.white
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

		collectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: TagCollectionViewCell.cellIdentifier)

		contentView.addSubview(collectionView)

		constrain(collectionView, contentView) { collectionView, contentView in
			collectionView.edges == contentView.edges
		}
	}

	open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return tags?.count ?? 0
	}

	open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.cellIdentifier, for: indexPath) as! TagCollectionViewCell
		let tag = tags![(indexPath as NSIndexPath).row]

		cell.tagLabel.text = tag

		return cell
	}

	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let tag = tags![(indexPath as NSIndexPath).row]

		return CGSize(width: TagCollectionViewCell.widthForTag(tag), height: collectionView.frame.height)
	}

	open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.tagsTableViewCell(self, didSelectTag: self.tags![(indexPath as NSIndexPath).row])
	}

	open override func layoutSubviews() {
		super.layoutSubviews()

		collectionView.reloadData()
	}
}
