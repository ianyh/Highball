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
    private let completion: ((Bool) -> ())

    init(completion: (Bool) -> ()) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let backgroundButton = UIButton(type: .System)
        let playButton = UIButton(type: .System)
        let volumeView = MPVolumeView()

        backgroundButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        backgroundButton.setTitle("", forState: .Normal)
        backgroundButton.addTarget(self, action: Selector("cancel"), forControlEvents: .TouchUpInside)

        playButton.setTitle("Play", forState: .Normal)
        playButton.addTarget(self, action: Selector("play"), forControlEvents: .TouchUpInside)

        volumeView.alpha = 1.0

        view.addSubview(backgroundButton)
        view.addSubview(playButton)
        view.addSubview(volumeView)

        constrain(backgroundButton, view) { backgroundButton, view in
            backgroundButton.edges == view.edges
        }

        constrain(playButton, view) { playButton, view in
            playButton.centerX == view.centerX
            playButton.bottom == view.centerY - 5
            playButton.width == 60
            playButton.height == 50
        }

        constrain(volumeView, view) { volumeView, view in
            volumeView.left == view.left + 30
            volumeView.right == view.right - 30
            volumeView.top == view.centerY + 5
            volumeView.height == 50
        }
    }

    func play() {
        finish(true)
    }

    func cancel() {
        finish(false)
    }

    private func finish(play: Bool) {
        completion(play)
        dismissViewControllerAnimated(true, completion: nil)
    }
}
