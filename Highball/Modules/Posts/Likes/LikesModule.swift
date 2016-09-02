//
//  LikesModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public struct LikesModule {
	public let viewController: LikesViewController
	private let presenter: LikesPresenter
	private let dataManager: PostsDataManager

	public init(postHeightCache: PostHeightCache) {
		viewController = LikesViewController(postHeightCache: postHeightCache)
		presenter = LikesPresenter()
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension LikesModule: Module {}
