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
		layout.scrollDirection = UICollectionViewScrollDirection.horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0

		imagesCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
		imagesCollectionView.dataSource = self
		imagesCollectionView.delegate = self
		imagesCollectionView.isPagingEnabled = true
		imagesCollectionView.showsHorizontalScrollIndicator = false
		imagesCollectionView.showsVerticalScrollIndicator = false

		imagesCollectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.cellIdentifier)

		view.addSubview(imagesCollectionView)
	}

	override func viewDidAppear(_ animated: Bool) {
		imagesCollectionView.reloadData()
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return post?.photos.count ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.cellIdentifier, for: indexPath)
		guard let imageCell = cell as? ImageCollectionViewCell else {
			return cell
		}
		let postPhoto = post!.photos[(indexPath as NSIndexPath).row]

		imageCell.contentWidth = collectionView.frame.size.width
		imageCell.photo = postPhoto
		imageCell.onTapHandler = { self.dismiss(animated: true, completion: nil) }

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		dismiss(animated: true, completion: nil)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return collectionView.frame.size
	}
}
