//
//  StreamImageCell.swift
//  Ello
//
//  Created by Sean Dougherty on 11/22/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import FLAnimatedImage
import PINRemoteImage
import Alamofire

public class StreamImageCell: StreamRegionableCell {
    static let reuseIdentifier = "StreamImageCell"

    // this little hack prevents constraints from breaking on initial load
    override public var bounds: CGRect {
        didSet {
          contentView.frame = bounds
        }
    }

    public struct Size {
        static let bottomMargin = CGFloat(10)
    }

    @IBOutlet public weak var imageView: FLAnimatedImageView!
    @IBOutlet public weak var imageButton: UIView!
    @IBOutlet public weak var circle: PulsingCircle!
    @IBOutlet public weak var failImage: UIImageView!
    @IBOutlet public weak var failBackgroundView: UIView!
    @IBOutlet public weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet public weak var failWidthConstraint: NSLayoutConstraint!
    @IBOutlet public weak var failHeightConstraint: NSLayoutConstraint!

    // not used in StreamEmbedCell
    @IBOutlet public weak var largeImagePlayButton: UIImageView?
    @IBOutlet public weak var imageRightConstraint: NSLayoutConstraint!

    weak var streamImageCellDelegate: StreamImageCellDelegate?
    weak var streamEditingDelegate: StreamEditingDelegate?
    public var isGif = false
    public typealias OnHeightMismatch = (CGFloat) -> Void
    public var onHeightMismatch: OnHeightMismatch?
    var request: Request?
    public var tallEnoughForFailToShow = true
    public var presentedImageUrl: NSURL?
    var serverProvidedAspectRatio: CGFloat?
    public var isLargeImage: Bool {
        get { return !(largeImagePlayButton?.hidden ?? true) }
        set {
            largeImagePlayButton?.image = InterfaceImage.VideoPlay.normalImage
            largeImagePlayButton?.hidden = !newValue
        }
    }

    private var imageSize: CGSize?
    private var aspectRatio: CGFloat? {
        guard let imageSize = imageSize else { return nil }
        return imageSize.width / imageSize.height
    }

    var calculatedHeight: CGFloat? {
        guard let aspectRatio = aspectRatio else {
            return nil
        }
        return frame.width / aspectRatio
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        if let playButton = largeImagePlayButton {
            playButton.image = InterfaceImage.VideoPlay.normalImage
        }

        let doubleTapGesture = UITapGestureRecognizer()
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(imageDoubleTapped(_:)))
        imageButton.addGestureRecognizer(doubleTapGesture)

        let singleTapGesture = UITapGestureRecognizer()
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.addTarget(self, action: #selector(imageTapped))
        singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        imageButton.addGestureRecognizer(singleTapGesture)

        let longPressGesture = UILongPressGestureRecognizer()
        longPressGesture.addTarget(self, action: #selector(imageLongPressed(_:)))
        imageButton.addGestureRecognizer(longPressGesture)
    }

    public func setImageURL(url: NSURL) {
        imageView.image = nil
        imageView.alpha = 0
        circle.pulse()
        failImage.hidden = true
        failImage.alpha = 0
        imageView.backgroundColor = UIColor.whiteColor()
        loadImage(url)
    }

    public func setImage(image: UIImage) {
        imageView.pin_cancelImageDownload()
        imageView.image = image
        imageView.alpha = 0
        failImage.hidden = true
        failImage.alpha = 0
        imageView.backgroundColor = UIColor.whiteColor()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let aspectRatio = aspectRatio, imageSize = imageSize else { return }

        let viewRatio = self.imageView.frame.width / self.imageView.frame.height
        if viewRatio != aspectRatio {
            let width = min(imageSize.width, self.frame.width)
            let actualHeight: CGFloat = ceil(width / aspectRatio) + Size.bottomMargin
            self.onHeightMismatch?(actualHeight)
        }
    }

    private func loadImage(url: NSURL) {
        self.imageView.pin_setImageFromURL(url) { result in
            let success = result.image != nil || result.animatedImage != nil
            let isAnimated = result.animatedImage != nil
            if success {
                self.layoutIfNeeded()
                let imageSize = isAnimated ? result.animatedImage.size : result.image.size
                self.imageSize = imageSize

                if self.serverProvidedAspectRatio == nil {
                    postNotification(StreamNotification.AnimateCellHeightNotification, value: self)
                }

                if result.resultType != .MemoryCache {
                    self.imageView.alpha = 0
                    UIView.animateWithDuration(0.3,
                        delay:0.0,
                        options:UIViewAnimationOptions.CurveLinear,
                        animations: {
                            self.imageView.alpha = 1.0
                        }, completion: { _ in
                            self.circle.stopPulse()
                        })
                }
                else {
                    self.imageView.alpha = 1.0
                    self.circle.stopPulse()
                }
            }
            else {
                self.imageLoadFailed()
            }
        }
    }

    private func imageLoadFailed() {
        failImage.hidden = false
        failBackgroundView.hidden = false
        circle.stopPulse()
        imageSize = nil
        largeImagePlayButton?.hidden = true
        nextTick { postNotification(StreamNotification.AnimateCellHeightNotification, value: self) }
        UIView.animateWithDuration(0.15) {
            self.failImage.alpha = 1.0
            self.imageView.backgroundColor = UIColor.greyF1()
            self.failBackgroundView.backgroundColor = UIColor.greyF1()
            self.imageView.alpha = 1.0
            self.failBackgroundView.alpha = 1.0
        }
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        imageButton.userInteractionEnabled = true
        onHeightMismatch = nil
        request?.cancel()
        imageView.image = nil
        imageView.animatedImage = nil
        imageView.pin_cancelImageDownload()

        isGif = false
        presentedImageUrl = nil
        isLargeImage = false
        failImage.hidden = true
        failImage.alpha = 0
        failBackgroundView.hidden = true
        failBackgroundView.alpha = 0
    }

    @IBAction func imageTapped() {
        streamImageCellDelegate?.imageTapped(self.imageView, cell: self)
    }

    @IBAction func imageDoubleTapped(gesture: UIGestureRecognizer) {
        let location = gesture.locationInView(nil)
        streamEditingDelegate?.cellDoubleTapped(self, location: location)
    }

    @IBAction func imageLongPressed(gesture: UIGestureRecognizer) {
        if gesture.state == .Began {
            streamEditingDelegate?.cellLongPressed(self)
        }
    }
}
