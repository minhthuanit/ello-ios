//
//  StreamImageViewer.swift
//  Ello
//
//  Created by Sean on 1/27/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import FLAnimatedImage
import JTSImageViewController

public class StreamImageViewer: NSObject {
    var prevWindowSize: CGSize?

    let presentingController: StreamViewController
    weak var imageView: UIImageView?

    public init(presentingController: StreamViewController) {
        self.presentingController = presentingController
    }
}


// MARK: Public
extension StreamImageViewer {
    public func imageTapped(imageView: FLAnimatedImageView, imageURL: NSURL?) {
        // tell AppDelegate to allow rotation
        AppDelegate.restrictRotation = false
        prevWindowSize = UIWindow.windowSize()

        self.imageView = imageView
        imageView.hidden = true
        let imageInfo = JTSImageInfo()
        if let imageURL = imageURL {
            imageInfo.imageURL = imageURL
        }
        else {
            imageInfo.image = imageView.image
        }
        imageInfo.referenceRect = imageView.frame
        imageInfo.referenceView = imageView.superview
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: JTSImageViewControllerMode.Image, backgroundStyle: JTSImageViewControllerBackgroundOptions.None)
        let transition: JTSImageViewControllerTransition = .FromOriginalPosition
        imageViewer.showFromViewController(presentingController, transition: transition)
        imageViewer.optionsDelegate = self
        imageViewer.dismissalDelegate = self
    }
}


// MARK: JTSImageViewControllerOptionsDelegate
extension StreamImageViewer: JTSImageViewControllerOptionsDelegate {
    public func alphaForBackgroundDimmingOverlayInImageViewer(imageViewer: JTSImageViewController) -> CGFloat {
        return 1.0
    }
}


// MARK: JTSImageViewControllerDismissalDelegate
extension StreamImageViewer: JTSImageViewControllerDismissalDelegate {
    public func imageViewerDidDismiss(imageViewer: JTSImageViewController) {
        if let prevSize = prevWindowSize where prevSize != UIWindow.windowSize() {
            postNotification(Application.Notifications.ViewSizeWillChange, value: UIWindow.windowSize())
        }
    }

    public func imageViewerWillDismiss(imageViewer: JTSImageViewController) {
        self.imageView?.hidden = false
        AppDelegate.restrictRotation = true
    }

    public func imageViewerWillAnimateDismissal(imageViewer: JTSImageViewController, withContainerView containerView: UIView, duration: CGFloat) {}
}
