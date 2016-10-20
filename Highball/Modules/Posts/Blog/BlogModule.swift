//
//  BlogModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public struct BlogModule {
	public let viewController: BlogViewController
	fileprivate let presenter: BlogPresenter
	fileprivate let dataManager: PostsDataManager

	public init(blogName: String, postHeightCache: PostHeightCache) {
		viewController = BlogViewController(blogName: blogName, postHeightCache: postHeightCache)
		presenter = BlogPresenter(blogName: blogName)
		dataManager = PostsDataManager(postHeightCache: postHeightCache, delegate: presenter)

		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager
	}
}

extension BlogModule: Module {}
