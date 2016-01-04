//
//  ReblogTransitionAnimator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/7/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ReblogTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	var presenting = true

	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.2
	}

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		guard
			let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
			let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
		else {
			return
		}

		if presenting {
			toViewController.view.alpha = 0
			toViewController.view.frame = fromViewController.view.frame

			transitionContext.containerView()!.addSubview(toViewController.view)

			toViewController.viewWillAppear(true)
			fromViewController.viewWillDisappear(true)

			UIView.animateWithDuration(
				transitionDuration(transitionContext),
				animations: {
					fromViewController.view.tintAdjustmentMode = .Dimmed
					toViewController.view.alpha = 1
				},
				completion: { finished in
					transitionContext.completeTransition(finished)
					if finished {
						toViewController.viewDidAppear(true)
						fromViewController.viewDidDisappear(true)
					}
				}
			)
		} else {
			toViewController.viewWillAppear(true)
			fromViewController.viewWillDisappear(true)

			UIView.animateWithDuration(
				transitionDuration(transitionContext),
				animations: {
					toViewController.view.tintAdjustmentMode = .Normal
					fromViewController.view.alpha = 0
				},
				completion: { finished in
					transitionContext.completeTransition(finished)
					if finished {
						toViewController.viewDidAppear(true)
						fromViewController.viewDidDisappear(true)
					}
				}
			)
		}
	}
}
