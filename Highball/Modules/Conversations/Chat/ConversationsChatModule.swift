//
//  ConversationsChatModule.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/6/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

open class ConversationsChatModule {
	open let viewController: ConversationsChatViewController
	fileprivate let presenter: ConversationsChatPresenter
	fileprivate let dataManager: ConversationsChatDataManager

	public init() {
		viewController = ConversationsChatViewController()
		presenter = ConversationsChatPresenter()
		dataManager = ConversationsChatDataManager()
	}
}

extension ConversationsChatModule: Module {}
