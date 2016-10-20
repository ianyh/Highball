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

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.2
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
			let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
		else {
			return
		}

		if presenting {
			toViewController.view.alpha = 0
			toViewController.view.frame = fromViewController.view.frame

			transitionContext.containerView.addSubview(toViewController.view)

			toViewController.viewWillAppear(true)
			fromViewController.viewWillDisappear(true)

			UIView.animate(
				withDuration: transitionDuration(using: transitionContext),
				animations: {
					fromViewController.view.tintAdjustmentMode = .dimmed
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

			UIView.animate(
				withDuration: transitionDuration(using: transitionContext),
				animations: {
					toViewController.view.tintAdjustmentMode = .normal
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
