//
//  TagModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

struct TagModule {
	let viewController: TagViewController
	fileprivate let presenter: TagPresenter
	fileprivate let dataManager: PostsDataManager

	init(tag: String, postHeightCache: PostHeightCache) {
		viewController = TagViewController(tag: tag, postHeightCache: postHeightCache)
		presenter = TagPresenter(tag: tag)
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension TagModule: Module {}
