//
//  ConversationsChatViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/6/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import SlackTextViewController

public protocol ConversationsChatView: class {
	
}

public class ConversationsChatViewController: SLKTextViewController {
	public var presenter: ConversationsChatPresenter?
}
