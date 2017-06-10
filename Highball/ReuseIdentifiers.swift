//
//  UITableViewCell+ReuseIdentifiers.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

extension UITableViewCell {
	static var cellIdentifier: String { return NSStringFromClass(self) }
}

extension UICollectionViewCell {
	static var cellIdentifier: String { return NSStringFromClass(self) }
}

extension UITableViewHeaderFooterView {
	static var viewIdentifier: String { return NSStringFromClass(self) }
}
