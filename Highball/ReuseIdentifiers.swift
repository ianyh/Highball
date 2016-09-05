//
//  UITableViewCell+ReuseIdentifiers.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit

public extension UITableViewCell {
	public static var cellIdentifier: String { return NSStringFromClass(self) }
}

public extension UICollectionViewCell {
	public static var cellIdentifier: String { return NSStringFromClass(self) }
}

public extension UITableViewHeaderFooterView {
	public static var viewIdentifier: String { return NSStringFromClass(self) }
}
