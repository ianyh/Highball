//
//  TagModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public struct TagModule {
	public let viewController: TagViewController
	private let presenter: TagPresenter
	private let dataManager: PostsDataManager

	public init(tag: String, postHeightCache: PostHeightCache) {
		viewController = TagViewController(tag: tag, postHeightCache: postHeightCache)
		presenter = TagPresenter(tag: tag)
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension TagModule: Module {}
