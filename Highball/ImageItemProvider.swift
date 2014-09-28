//
//  ImageItemProvider.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/10/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ImageItemProvider: UIActivityItemProvider {
    var image: UIImage?

    override func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        return self.image
    }
}
