//
//  Module.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import UIKit

public protocol Module {
	associatedtype ViewController: UIViewController

	var viewController: ViewController { get }
	func installInNavigationController(_ navigationController: UINavigationController)
}

public extension Module {
	public func installInNavigationController(_ navigationController: UINavigationController) {
		navigationController.pushViewController(viewController, animated: true)
	}
}
