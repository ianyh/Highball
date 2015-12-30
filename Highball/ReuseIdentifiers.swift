//
//  UITableViewCell+ReuseIdentifiers.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

extension UITableViewCell {
    class var cellIdentifier: String { return NSStringFromClass(self) }
}

extension UICollectionViewCell {
    class var cellIdentifier: String { return NSStringFromClass(self) }
}

extension UITableViewHeaderFooterView {
    class var viewIdentifier: String { return NSStringFromClass(self) }
}
