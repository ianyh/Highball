//
//  DataActivityItemSource.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 6/10/17.
//  Copyright © 2017 ianynda. All rights reserved.
//

import UIKit
import UTIKit

final class DataActivityItemSource: NSObject {
	let url: URL

	init(url: URL) {
		self.url = url
		super.init()
	}
}

extension DataActivityItemSource: UIActivityItemSource {
	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		return url
	}

	func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
		guard let data = try? Data(contentsOf: url) else {
			return nil
		}

		return data
	}

	func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
		return UTI(filenameExtension: url.pathExtension)?.utiString ?? "public.data"
	}
}
