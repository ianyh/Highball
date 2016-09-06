//
//  ConversationsListModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public class ConversationsListModule {
	public let viewController = ConversationsListViewController()
	private let presenter = ConversationsListPresenter()
	private let dataManager = ConversationsListDataManager()

	public init() {
		viewController.presenter = presenter

		presenter.view = viewController
		presenter.dataManager = dataManager

		dataManager.delegate = presenter
	}
}

extension ConversationsListModule: Module {}
