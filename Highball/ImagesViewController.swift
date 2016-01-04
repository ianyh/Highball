//
//  ImagesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ImagesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	var imagesCollectionView: UICollectionView!
	var post: Post?

	override func viewDidLoad() {
		super.viewDidLoad()

		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0

		imagesCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
		imagesCollectionView.dataSource = self
		imagesCollectionView.delegate = self
		imagesCollectionView.pagingEnabled = true
		imagesCollectionView.showsHorizontalScrollIndicator = false
		imagesCollectionView.showsVerticalScrollIndicator = false

		imagesCollectionView.registerClass(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.cellIdentifier)

		view.addSubview(imagesCollectionView)
	}

	override func viewDidAppear(animated: Bool) {
		imagesCollectionView.reloadData()
	}

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return post?.photos.count ?? 0
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCollectionViewCell.cellIdentifier, forIndexPath: indexPath)
		guard let imageCell = cell as? ImageCollectionViewCell else {
			return cell
		}
		let postPhoto = post!.photos[indexPath.row]

		imageCell.contentWidth = collectionView.frame.size.width
		imageCell.photo = postPhoto
		imageCell.onTapHandler = { self.dismissViewControllerAnimated(true, completion: nil) }

		return cell
	}

	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		dismissViewControllerAnimated(true, completion: nil)
	}

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return collectionView.frame.size
	}
}
