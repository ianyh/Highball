//
//  VideoPlayController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/28/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import MediaPlayer
import Cartography

class VideoPlayController: UIViewController {
    private var completion: ((Bool) -> ())!

    required init(completion: (Bool) -> ()) {
        super.init(nibName: nil, bundle: nil)
        self.completion = completion
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let backgroundButton = UIButton(type: .System)
        let playButton = UIButton(type: .System)
        let volumeView = MPVolumeView()

        backgroundButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        backgroundButton.setTitle("", forState: UIControlState.Normal)
        backgroundButton.addTarget(self, action: Selector("cancel"), forControlEvents: UIControlEvents.TouchUpInside)

        playButton.setTitle("Play", forState: UIControlState.Normal)
        playButton.addTarget(self, action: Selector("play"), forControlEvents: UIControlEvents.TouchUpInside)

        volumeView.alpha = 1.0

        self.view.addSubview(backgroundButton)
        self.view.addSubview(playButton)
        self.view.addSubview(volumeView)

        constrain(backgroundButton, self.view) { backgroundButton, view in
            backgroundButton.edges == view.edges; return
        }

        constrain(playButton, self.view) { playButton, view in
            playButton.centerX == view.centerX
            playButton.bottom == view.centerY - 5
            playButton.width == 60
            playButton.height == 50
        }

        constrain(volumeView, self.view) { volumeView, view in
            volumeView.left == view.left + 30
            volumeView.right == view.right - 30
            volumeView.top == view.centerY + 5
            volumeView.height == 50
        }
    }

    func play() {
        self.finish(true)
    }

    func cancel() {
        self.finish(false)
    }

    private func finish(play: Bool) {
        let completion = self.completion
        self.completion = nil
        completion(play)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
