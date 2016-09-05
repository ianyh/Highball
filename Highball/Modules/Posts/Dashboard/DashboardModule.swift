//
//  DashboardModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public struct DashboardModule {
	public let viewController: DashboardViewController
	private let presenter = DashboardPresenter()
	private let dataManager: PostsDataManager

	public init(postHeightCache: PostHeightCache) {
		viewController = DashboardViewController(postHeightCache: postHeightCache)
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension DashboardModule: Module {}
