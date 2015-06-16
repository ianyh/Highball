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
    
    let imageCollectionViewCellIdentifier = "imageCollectionViewCellIdentifier"

    var post: Post?

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        self.imagesCollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.imagesCollectionView.delegate = self
        self.imagesCollectionView.dataSource = self
        self.imagesCollectionView.pagingEnabled = true
        self.imagesCollectionView.showsHorizontalScrollIndicator = false
        self.imagesCollectionView.showsVerticalScrollIndicator = false

        self.imagesCollectionView.registerClass(ImageCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: imageCollectionViewCellIdentifier)

        self.view.addSubview(self.imagesCollectionView)
    }

    override func viewDidAppear(animated: Bool) {
        self.imagesCollectionView.reloadData()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let post = self.post {
            return post.photos.count
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(imageCollectionViewCellIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
        let postPhoto = self.post!.photos[indexPath.row]

        cell.contentWidth = collectionView.frame.size.width
        cell.photo = postPhoto
        cell.onTapHandler = { self.dismissViewControllerAnimated(true, completion: nil) }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
