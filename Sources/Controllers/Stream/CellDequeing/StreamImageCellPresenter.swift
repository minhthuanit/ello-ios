//
//  StreamImageCellPresenter.swift
//  Ello
//
//  Created by Sean on 2/18/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

public struct StreamImageCellPresenter {

    static let singleColumnFailWidth: CGFloat = 140
    static let singleColumnFailHeight: CGFloat = 160
    static let multiColumnFailWidth: CGFloat = 70
    static let multiColumnFailHeight: CGFloat = 80

    static func preventImageStretching(cell: StreamImageCell, attachmentWidth: Int, columnWidth: CGFloat, leftMargin: CGFloat = 0) {
        let width = CGFloat(attachmentWidth)
        if width < columnWidth - leftMargin {
            cell.imageRightConstraint.constant = columnWidth - width - leftMargin
        }
        else {
            cell.imageRightConstraint.constant = 0
        }
    }

    static func configureCellWidthAndLayout(
        cell: StreamImageCell,
        imageRegion: ImageRegion,
        streamCellItem: StreamCellItem) -> CGFloat
    {
        // Repost specifics
        if imageRegion.isRepost == true {
            cell.leadingConstraint.constant = StreamTextCellPresenter.repostMargin
            cell.showBorder()
        }
        else if let _ = streamCellItem.jsonable as? ElloComment {
            cell.leadingConstraint.constant = StreamTextCellPresenter.commentMargin
        }
        else {
            cell.leadingConstraint.constant = 0.0
        }

        return cell.leadingConstraint.constant
    }

    public static func configure(
        cell: UICollectionViewCell,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        indexPath: NSIndexPath,
        currentUser: User?)
    {
        if let cell = cell as? StreamImageCell,
            imageRegion = streamCellItem.type.data as? ImageRegion
        {
            cell.imageRightConstraint?.constant = 0
            cell.failImage.hidden = true
            cell.failImage.alpha = 0
            var attachmentToLoad: Attachment?
            var imageToLoad: NSURL?
            var showGifInThisCell = false
            if let asset = imageRegion.asset where asset.isGif {
                if streamKind.supportsLargeImages || !asset.isLargeGif {
                    attachmentToLoad = asset.optimized
                    imageToLoad = asset.optimized?.url
                    showGifInThisCell = true
                }
                else {
                    cell.presentedImageUrl = asset.optimized?.url
                    cell.isLargeImage = true
                }
                cell.isGif = true
            }

            if streamKind.isGridView {
                cell.failWidthConstraint.constant = StreamImageCellPresenter.multiColumnFailWidth
                cell.failHeightConstraint.constant = StreamImageCellPresenter.multiColumnFailHeight
                attachmentToLoad = attachmentToLoad ?? imageRegion.asset?.gridLayoutAttachment
            }
            else {
                cell.failWidthConstraint.constant = StreamImageCellPresenter.singleColumnFailWidth
                cell.failHeightConstraint.constant = StreamImageCellPresenter.singleColumnFailHeight
                attachmentToLoad = attachmentToLoad ?? imageRegion.asset?.oneColumnAttachment
            }

            let imageToShow = attachmentToLoad?.image
            imageToLoad = imageToLoad ?? attachmentToLoad?.url

            cell.hideBorder()
            let margin = configureCellWidthAndLayout(cell, imageRegion: imageRegion, streamCellItem: streamCellItem)
            if let attachmentWidth = attachmentToLoad?.width {
                let columnWidth: CGFloat = calculateColumnWidth(screenWidth: UIWindow.windowWidth(), columnCount: streamKind.columnCountFor(width: cell.frame.width))
                preventImageStretching(cell, attachmentWidth: attachmentWidth, columnWidth: columnWidth, leftMargin: margin)
            }
            cell.layoutIfNeeded()

            cell.onHeightMismatch = { actualHeight in
                streamCellItem.calculatedWebHeight = actualHeight
                streamCellItem.calculatedOneColumnCellHeight = actualHeight
                streamCellItem.calculatedMultiColumnCellHeight = actualHeight
                postNotification(StreamNotification.UpdateCellHeightNotification, value: cell)
            }

            if let image = imageToShow where !showGifInThisCell {
                cell.setImage(image)
            }
            else if let imageURL = imageToLoad {
                cell.serverProvidedAspectRatio = StreamImageCellSizeCalculator.aspectRatioForImageRegion(imageRegion)
                cell.setImageURL(imageURL)
            }
            else if let imageURL = imageRegion.url {
                cell.isGif = imageURL.hasGifExtension
                cell.setImageURL(imageURL)
            }
        }
    }
}
