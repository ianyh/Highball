//
//  LikesModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

struct LikesModule {
	let viewController: LikesViewController
	fileprivate let presenter: LikesPresenter
	fileprivate let dataManager: PostsDataManager

	init(postHeightCache: PostHeightCache) {
		viewController = LikesViewController(postHeightCache: postHeightCache)
		presenter = LikesPresenter()
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension LikesModule: Module {}
