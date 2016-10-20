//
//  QuickReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import ChameleonFramework
import FontAwesomeKit
import pop
import UIKit

public enum QuickReblogAction {
	case reblog(ReblogType)
	case share
	case like
}

open class QuickReblogViewController: UIViewController {
	open var startingPoint: CGPoint!
	open var post: Post!

	fileprivate let radius: CGFloat = 70

	fileprivate var backgroundButton: UIButton!

	fileprivate var startButton: UIButton!

	fileprivate var reblogButton: UIButton!
	fileprivate var queueButton: UIButton!
	fileprivate var shareButton: UIButton!
	fileprivate var likeButton: UIButton!

	fileprivate var selectedButton: UIButton? {
		didSet {
			for button in [ reblogButton, queueButton, shareButton, likeButton ] {
				if button == selectedButton {
					let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
					scaleAnimation?.toValue = NSValue(cgSize: CGSize(width: 1.5, height: 1.5))
					scaleAnimation?.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
					button?.pop_removeAnimation(forKey: "selectedScale")
					button?.pop_add(scaleAnimation, forKey: "selectedScale")

					let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
					backgroundColorAnimation?.toValue = backgroundColorForButton(button!).cgColor
					button?.pop_removeAnimation(forKey: "selectedBackgroundColor")
					button?.pop_add(backgroundColorAnimation, forKey: "selectedBackgroundColor")
				} else {
					let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
					scaleAnimation?.toValue = NSValue(cgSize: CGSize(width: 1, height: 1))
					scaleAnimation?.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
					button?.pop_removeAnimation(forKey: "selectedScale")
					button?.pop_add(scaleAnimation, forKey: "selectedScale")

					let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
					backgroundColorAnimation?.toValue = backgroundColorForButton(button!)
					button?.pop_removeAnimation(forKey: "selectedBackgroundColor")
					button?.pop_add(backgroundColorAnimation, forKey: "selectedBackgroundColor")
				}
			}
		}
	}

	open var showingOptions: Bool = false {
		didSet {
			startButton.layer.pop_removeAllAnimations()
			reblogButton.layer.pop_removeAllAnimations()
			queueButton.layer.pop_removeAllAnimations()
			shareButton.layer.pop_removeAllAnimations()
			likeButton.layer.pop_removeAllAnimations()

			if showingOptions {
				for button in [ reblogButton, queueButton, shareButton, likeButton ] {
					let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
					opacityAnimation?.toValue = 1
					opacityAnimation?.name = "opacity"

					button?.layer.pop_add(opacityAnimation, forKey: opacityAnimation?.name)
				}

				let onLeft = startButton.center.x < view.bounds.midX
				let center = view.convert(startButton.center, to: nil)
				let distanceFromTop = center.y + 50
				let distanceFromBottom = UIScreen.main.bounds.height - center.y - 50
				var angleFromTop: CGFloat = CGFloat(-M_PI_2) / 3
				var angleFromBottom: CGFloat = CGFloat(-M_PI_2) / 3

				if distanceFromTop < radius {
					angleFromTop = acos(distanceFromTop / radius)
				}

				if distanceFromBottom < radius {
					angleFromBottom = acos(distanceFromBottom / radius)
				}

				let startAngle = CGFloat(M_PI_2) + angleFromTop
				let endAngle = CGFloat(M_PI + M_PI_2) - angleFromBottom
				let initialAngle = startAngle + (endAngle - startAngle) / 8
				let angleInterval = (endAngle - startAngle) / 4

				for (index, button) in [ reblogButton, queueButton, shareButton, likeButton ].enumerated() {
					let center = startButton.center
					let angleOffset = angleInterval * CGFloat(index)
					let angle = initialAngle + angleOffset
					let y = center.y - radius * sin(angle)
					var x: CGFloat!
					if onLeft {
						x = center.x - radius * cos(angle)
					} else {
						x = center.x + radius * cos(angle)
					}
					let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)

					positionAnimation?.toValue = NSValue(cgPoint: CGPoint(x: x, y: y))
					positionAnimation?.springBounciness = 20
					positionAnimation?.name = "move"
					positionAnimation?.beginTime = CACurrentMediaTime() + 0.01

					button?.layer.position = startButton.center
					button?.layer.pop_add(positionAnimation, forKey: positionAnimation?.name)
				}
			} else {
				for button in [ reblogButton, queueButton, shareButton, likeButton ] {
					let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
					opacityAnimation?.toValue = 0
					opacityAnimation?.name = "opacity"

					button?.layer.pop_add(opacityAnimation, forKey: opacityAnimation?.name)

					let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
					positionAnimation?.toValue = NSValue(cgPoint: startButton.center)
					positionAnimation?.name = "moveReblog"

					button?.layer.pop_add(positionAnimation, forKey: positionAnimation?.name)
				}
			}
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		view.isOpaque = false
		view.backgroundColor = UIColor.black.withAlphaComponent(0.3)

		backgroundButton = UIButton(type: .system)

		startButton = UIButton(type: .system)
		startButton.setImage(UIImage(named: "Reblog"), for: UIControlState())
		startButton.tintColor = UIColor.gray
		startButton.sizeToFit()

		reblogButton = UIButton(type: .system)
		reblogButton.setImage(FAKIonIcons.iosLoopStrongIcon(withSize: 25).image(with: CGSize(width: 25, height: 25)), for: UIControlState())

		queueButton = UIButton(type: .system)
		queueButton.setImage(FAKIonIcons.iosListOutlineIcon(withSize: 25).image(with: CGSize(width: 25, height: 25)), for: UIControlState())

		shareButton = UIButton(type: .system)
		shareButton.setImage(FAKIonIcons.iosUploadOutlineIcon(withSize: 25).image(with: CGSize(width: 25, height: 25)), for: UIControlState())

		likeButton = UIButton(type: .system)
		likeButton.setImage(FAKIonIcons.iosHeartOutlineIcon(withSize: 25).image(with: CGSize(width: 25, height: 25)), for: UIControlState())

		view.addSubview(backgroundButton)
		view.addSubview(startButton)
		view.addSubview(reblogButton)
		view.addSubview(queueButton)
		view.addSubview(shareButton)
		view.addSubview(likeButton)

		constrain(backgroundButton, view) { backgroundButton, view in
			backgroundButton.edges == view.edges
		}

		constrain(startButton, view) { startButton, view in
			startButton.centerX == view.left + self.startingPoint.x
			startButton.centerY == view.top + self.startingPoint.y
			startButton.height == 40
			startButton.width == 40
		}

		for button in [ reblogButton, queueButton, shareButton, likeButton ] {
			button?.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
			button?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
			button?.tintColor = UIColor.white
			button?.backgroundColor = backgroundColorForButton(button!)
			button?.layer.cornerRadius = 30
			button?.layer.opacity = 0
			button?.sizeToFit()
			constrain(button!, startButton) { button, startButton in
				button.center == startButton.center
				button.height == 60
				button.width == 60
			}
		}

		var startButtonFrame = startButton.frame
		startButtonFrame.origin = startingPoint
		startButton.frame = startButtonFrame
	}

	 open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		DispatchQueue.main.async { self.showingOptions = true }
	}
}

extension QuickReblogViewController {
	public func updateWithPoint(_ point: CGPoint) {
		guard let view = view.hitTest(point, with: nil), let button = view as? UIButton else {
			return
		}

		if button != selectedButton {
			selectedButton = button
		}
	}

	public func reblogAction() -> QuickReblogAction? {
		guard let selectedButton = selectedButton else {
			return nil
		}

		switch selectedButton {
		case self.reblogButton:
			return .reblog(.reblog)
		case self.queueButton:
			return .reblog(.queue)
		case self.shareButton:
			return .share
		case self.likeButton:
			return .like
		default:
			return nil
		}
	}

	public func backgroundColorForButton(_ button: UIButton) -> (UIColor) {
		var backgroundColor: UIColor!
		switch button {
		case reblogButton:
			backgroundColor = UIColor.flatBlack()
		case queueButton:
			backgroundColor = UIColor.flatBlack()
		case shareButton:
			backgroundColor = UIColor.flatBlack()
		case likeButton:
			if post.liked {
				backgroundColor = UIColor.flatRed()
			} else {
				backgroundColor = UIColor.flatBlack()
			}
		default:
			backgroundColor = UIColor.flatBlack()
		}

		if button == selectedButton {
			return backgroundColor
		}

		return backgroundColor.withAlphaComponent(0.75)
	}
}
