//
//  StreamImageCellSizeCalculator.swift
//  Ello
//
//  Created by Ryan Boyajian on 4/27/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

public class StreamImageCellSizeCalculator: NSObject {

    var screenWidth: CGFloat = 0.0
    var maxWidth: CGFloat = 0.0
    var columnCount: Int = 1
    public var cellItems: [StreamCellItem] = []
    public var completion: ElloEmptyCompletion = {}

// MARK: Static

    public static func aspectRatioForImageRegion(imageRegion: ImageRegion) -> CGFloat {
        if let asset = imageRegion.asset {
            var attachment: Attachment?
            if let tryAttachment = asset.hdpi {
                attachment = tryAttachment
            }
            else if let tryAttachment = asset.optimized {
                attachment = tryAttachment
            }

            if let attachment = attachment {
                if let width = attachment.width, height = attachment.height {
                    return CGFloat(width)/CGFloat(height)
                }
            }
        }
        return 4.0/3.0
    }

// MARK: Public

    public func processCells(cellItems: [StreamCellItem], withWidth width: CGFloat, columnCount: Int, completion: ElloEmptyCompletion) {
        self.completion = completion
        self.cellItems = cellItems
        self.screenWidth = width
        self.columnCount = columnCount
        loadNext()
    }

// MARK: Private

    private func loadNext() {
        self.maxWidth = screenWidth
        if !self.cellItems.isEmpty {
            let item = cellItems.removeAtIndex(0)
            if (item.type.data as? Regionable)?.isRepost == true {
                maxWidth -= StreamTextCellPresenter.repostMargin
            }
            else if item.jsonable is ElloComment {
                maxWidth -= StreamTextCellPresenter.commentMargin
            }

            if let imageRegion = item.type.data as? ImageRegion {
                item.calculatedOneColumnCellHeight = StreamImageCell.Size.bottomMargin + oneColumnImageHeight(imageRegion)
                item.calculatedMultiColumnCellHeight = StreamImageCell.Size.bottomMargin + multiColumnImageHeight(imageRegion)
            }
            else if let embedRegion = item.type.data as? EmbedRegion {
                var ratio: CGFloat!
                if embedRegion.isAudioEmbed || embedRegion.service == .UStream {
                    ratio = 1.0
                }
                else {
                    ratio = 16.0/9.0
                }
                item.calculatedOneColumnCellHeight = StreamImageCell.Size.bottomMargin + maxWidth / ratio
                item.calculatedMultiColumnCellHeight = StreamImageCell.Size.bottomMargin + calculateColumnWidth(screenWidth: maxWidth, columnCount: columnCount) / ratio
            }
            loadNext()
        }
        else {
            completion()
        }
    }

    private func oneColumnImageHeight(imageRegion: ImageRegion) -> CGFloat {
        var imageWidth = maxWidth
        if let assetWidth = imageRegion.asset?.oneColumnAttachment?.width {
            imageWidth = min(maxWidth, CGFloat(assetWidth))
        }
        return (imageWidth / StreamImageCellSizeCalculator.aspectRatioForImageRegion(imageRegion)) + 10
    }

    private func multiColumnImageHeight(imageBlock: ImageRegion) -> CGFloat {
        var imageWidth = calculateColumnWidth(screenWidth: maxWidth, columnCount: columnCount)
        if let assetWidth = imageBlock.asset?.gridLayoutAttachment?.width {
            imageWidth = min(imageWidth, CGFloat(assetWidth))
        }
        return ceil((imageWidth / StreamImageCellSizeCalculator.aspectRatioForImageRegion(imageBlock)) + 10)
    }

}
