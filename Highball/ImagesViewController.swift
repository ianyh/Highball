//
//  ImagesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ImagesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let imageCollectionViewCellIdentifier = "imageCollectionViewCellIdentifier"

    var post: Post?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.registerClass(ImageCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: imageCollectionViewCellIdentifier)
    }

    override func viewDidAppear(animated: Bool) {
        self.collectionView.reloadData()
    }

    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        if let post = self.post {
            return post.photos().count
        }
        return 0
    }

    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(imageCollectionViewCellIdentifier, forIndexPath: indexPath) as ImageCollectionViewCell!
        let postPhoto = self.post!.photos()[indexPath.row]

        cell.contentWidth = collectionView.frame.size.width
        cell.photo = postPhoto

        return cell
    }

    

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        return collectionView.frame.size
    }

}
