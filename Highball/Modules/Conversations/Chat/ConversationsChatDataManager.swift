//
//  ConversationsChatDataManager.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/6/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public protocol ConversationsChatDataManagerDelegate: class {
	
}

public class ConversationsChatDataManager {
	public weak var delegate: ConversationsChatDataManagerDelegate?
}
