//
//  PostActionsTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 6/11/17.
//  Copyright © 2017 ianynda. All rights reserved.
//

import Cartography
import UIKit

final class PostActionsTableViewCell: UITableViewCell {
	private let likeButton = UIButton(type: .system)

	var liked: Bool = false {
		didSet {
			likeButton.setTitle(liked ? "Unlike" : "Like", for: .normal)
		}
	}

	var handler: ((PostActionsTableViewCell) -> Void)?

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initializeViews()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func initializeViews() {
		likeButton.addTarget(self, action: #selector(handle), for: .touchUpInside)
		likeButton.setTitle("Like", for: .normal)

		contentView.addSubview(likeButton)

		constrain(likeButton, contentView) { likeButton, contentView in
			likeButton.edges == inset(contentView.edges, 10, 0)
			likeButton.height == 50
		}
	}

	func handle() {
		handler?(self)
	}
}
