//
//  LikesFiltersViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 6/10/17.
//  Copyright © 2017 ianynda. All rights reserved.
//

import Eureka
import Foundation

final class LikesFiltersViewController: FormViewController {
	private let completion: (String, Date?) -> Void

	init(completion: @escaping (String, Date?) -> Void) {
		self.completion = completion

		super.init(nibName: nil, bundle: nil)

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(apply))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		form
		+++ Section()
			<<< PushRow<String> {
				$0.tag = "type"
				$0.title = "type"
				$0.options = [
					"all",
					"photo",
					"video"
				]
				$0.value = "all"
				$0.selectorTitle = "Post Type"
			}

			<<< DateRow {
				$0.tag = "date"
				$0.title = "date"
			}
	}

	func cancel() {
		dismiss(animated: true, completion: nil)
	}

	func apply() {
		let values = form.values()
		let type = values["type"] as? String ?? "all"
		let date = values["date"] as? Date

		completion(type, date)
	}
}
