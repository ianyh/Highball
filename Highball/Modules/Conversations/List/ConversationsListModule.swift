//
//  ConversationsListModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

open class ConversationsListModule {
	open let viewController = ConversationsListViewController()
	fileprivate let presenter = ConversationsListPresenter()
	fileprivate let dataManager = ConversationsListDataManager()

	public init() {
		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager

		dataManager.delegate = presenter
	}
}

extension ConversationsListModule: Module {}
