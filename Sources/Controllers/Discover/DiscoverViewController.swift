//
//  DiscoverViewController.swift
//  Ello
//
//  Created by Sean Dougherty on 11/20/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import UIKit
import SVGKit

public class DiscoverViewController: StreamableViewController {

    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var navigationBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var chevron: UIImageView!
    @IBOutlet weak var inviteLabel: UILabel!

    override public var tabBarItem: UITabBarItem? {
        get { return UITabBarItem.svgItem("sparkles", insets: UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)) }
        set { self.tabBarItem = newValue }
    }

    required public init() {
        super.init(nibName: "DiscoverViewController", bundle: nil)
        title = NSLocalizedString("Discover", comment: "Discover")
        streamViewController.streamKind = .Discover(type: .Recommended, seed: ElloAPI.generateSeed(), perPage: 50)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        chevron.image = SVGKImage(named: "abracket_white.svg").UIImage!
        inviteLabel.text = NSLocalizedString("Find & invite your friends", comment: "Find & invite")
        inviteLabel.font = UIFont.typewriterFont(14)
        inviteLabel.textColor = .whiteColor()
        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateInsets()
    }

    private func updateInsets() {
        updateInsets(navBar: navigationBar, streamController: streamViewController)
    }

    override public func showNavBars(scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(navigationBar, visible: true, withConstraint: navigationBarTopConstraint)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override public func hideNavBars() {
        super.hideNavBars()
        positionNavBar(navigationBar, visible: false, withConstraint: navigationBarTopConstraint)
        updateInsets()
    }

    // MARK: - IBActions

    @IBAction func importMyContactsTapped(sender: UIButton) {
        let responder = targetForAction("onInviteFriends", withSender: self) as? InviteResponder
        responder?.onInviteFriends()
    }
}
